/*
 * server.cpp  —  Merged game + lobby server  v4
 *
 * Single executable. Handles all game traffic AND the lobby browser.
 * Writes lobby/match/stats data to Supabase (hosted PostgreSQL).
 * Replaces both server.exe and lobby_db_server.exe.
 *
 * ─── USAGE ───────────────────────────────────────────────────────────────────
 *
 *   server.exe <lobby_name> <public_ip> [password_hash]
 *
 *   lobby_name     Human-readable lobby name (quote if it contains spaces)
 *   public_ip      This machine's public IP that clients will connect to
 *   password_hash  (optional) djb2 hex hash of lobby password
 *
 *   Example (public):   server.exe "My Lobby" 203.0.113.10
 *   Example (private):  server.exe "Secret"   203.0.113.10 a3f1c9b2
 *
 * ─── PORTS ───────────────────────────────────────────────────────────────────
 *   7777  Game traffic  (player state, bullets, match control)
 *   8888  Lobby traffic (list requests, join requests from clients)
 *         Both ports on the same machine. Clients connect to public_ip.
 *
 * ─── SUPABASE SETUP ──────────────────────────────────────────────────────────
 *   1. Create a free project at https://supabase.com
 *   2. In the SQL editor, run the schema at the bottom of this file
 *   3. Go to Settings -> API and copy:
 *        Project URL  -> set SUPABASE_URL below
 *        anon/public key -> set SUPABASE_KEY below
 *
 * ─── BUILD ───────────────────────────────────────────────────────────────────
 *   Compile natively on Linux (the Droplet):
 *
 *   apt install -y g++ libcurl4-openssl-dev
 *   g++ server.cpp -o server -lcurl
 *
 * ─── SUPABASE SCHEMA (run once in Supabase SQL editor) ───────────────────────
 *
 *   CREATE TABLE lobbies (
 *     id              BIGSERIAL PRIMARY KEY,
 *     lobby_name      TEXT NOT NULL,
 *     host_ip         TEXT NOT NULL,
 *     host_port       INTEGER NOT NULL,
 *     max_players     INTEGER NOT NULL,
 *     current_players INTEGER NOT NULL DEFAULT 0,
 *     password_hash   TEXT DEFAULT NULL,
 *     is_active       BOOLEAN NOT NULL DEFAULT FALSE,
 *     match_id        BIGINT DEFAULT NULL,
 *     created_at      TIMESTAMPTZ DEFAULT NOW()
 *   );
 *
 *   CREATE TABLE matches (
 *     id          BIGSERIAL PRIMARY KEY,
 *     lobby_id    BIGINT NOT NULL,
 *     started_at  TIMESTAMPTZ DEFAULT NOW(),
 *     ended_at    TIMESTAMPTZ DEFAULT NULL
 *   );
 *
 *   CREATE TABLE players (
 *     id           BIGSERIAL PRIMARY KEY,
 *     pid          INTEGER NOT NULL,
 *     display_name TEXT NOT NULL DEFAULT 'Player',
 *     created_at   TIMESTAMPTZ DEFAULT NOW()
 *   );
 *
 *   CREATE TABLE match_players (
 *     id         BIGSERIAL PRIMARY KEY,
 *     match_id   BIGINT NOT NULL REFERENCES matches(id),
 *     player_id  BIGINT NOT NULL REFERENCES players(id),
 *     pid        INTEGER NOT NULL,
 *     kills      INTEGER NOT NULL DEFAULT 0,
 *     deaths     INTEGER NOT NULL DEFAULT 0
 *   );
 *
 *   -- Cumulative player stats linked to Supabase Auth
 *   CREATE TABLE profiles (
 *     user_id  UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
 *     username TEXT NOT NULL,
 *     wins     INTEGER NOT NULL DEFAULT 0,
 *     kills    INTEGER NOT NULL DEFAULT 0,
 *     deaths   INTEGER NOT NULL DEFAULT 0
 *   );
 *
 *   -- RPC to atomically increment stats (avoids race conditions)
 *   CREATE OR REPLACE FUNCTION increment_player_stats(
 *     user_id UUID, kills_inc INT, deaths_inc INT, wins_inc INT
 *   ) RETURNS void LANGUAGE plpgsql AS $$
 *   BEGIN
 *     INSERT INTO profiles(user_id, username, kills, deaths, wins)
 *     VALUES (user_id, (SELECT raw_user_meta_data->>'username' FROM auth.users WHERE id = user_id), kills_inc, deaths_inc, wins_inc)
 *     ON CONFLICT (user_id) DO UPDATE SET
 *       kills  = profiles.kills  + EXCLUDED.kills,
 *       deaths = profiles.deaths + EXCLUDED.deaths,
 *       wins   = profiles.wins   + EXCLUDED.wins;
 *   END;
 *   $$;
 */

#ifdef _WIN32
  #include <winsock2.h>
  #include <windows.h>
  #include <winhttp.h>
  #pragma comment(lib, "ws2_32.lib")
  #pragma comment(lib, "winhttp.lib")
  #define CLOSE_SOCK(s) closesocket(s)
  #define SOCK_T SOCKET
  #define INVALID_SOCK INVALID_SOCKET
  typedef int socklen_t;  // Windows uses int where POSIX uses socklen_t
  #define SOCKOPT_CAST (const char*)
#else
  #include <sys/socket.h>
  #include <netinet/in.h>
  #include <arpa/inet.h>
  #include <unistd.h>
  #include <fcntl.h>
  #include <curl/curl.h>
  #include <errno.h>
  #define CLOSE_SOCK(s) close(s)
  #define SOCK_T int
  #define INVALID_SOCK (-1)
  #define SOCKOPT_CAST (const void*)
#endif
#include <iostream>
#include <string>
#include <map>
#include <vector>
#include <cstdint>
#include <cstring>
#include <chrono>
#include <sstream>

// ═══════════════════════════════════════════════════════════════════════════
//  CONFIGURATION — set these to your Supabase project values
// ═══════════════════════════════════════════════════════════════════════════
#define SUPABASE_URL  "https://zqnvimeyzogmtgydrkuz.supabase.co"
#define SUPABASE_KEY  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpxbnZpbWV5em9nbXRneWRya3V6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY3MjcwNzEsImV4cCI6MjA5MjMwMzA3MX0.vRLJw3_Ve6Az-0K2PJphwg8cE9juG4y2p7VYMPbR5io"

// ── Fixed server config ───────────────────────────────────────────────────
static const uint16_t GAME_PORT   = 7777;
static const uint16_t LOBBY_PORT  = 8888;
static const uint16_t DISC_PORT   = 7779;  // LAN discovery broadcast port
static const uint8_t  MAX_PLAYERS = 4;
static const int      TIMEOUT_S   = 5;

// ── Game packet types (client <-> server) ─────────────────────────────────
#define PKT_PLAYER_STATE  1
#define PKT_ID_ASSIGN     2
#define PKT_PLAYER_LEFT   3
#define PKT_BULLET        4
#define PKT_TIMER         5
#define PKT_MATCH_END_BC  6
#define PKT_MATCH_START   7
#define PKT_NOT_ENOUGH    8
#define PKT_DISCONNECT    9
#define PKT_JOIN_REQUEST  10
#define PKT_KILL_REPORT   11
#define PKT_KEEPALIVE     12
#define PKT_DISCOVERY     40  // server reply to a discovery ping
#define PKT_DISCOVERY_PING 41 // joiner sends this to game port; server replies type-40

// ── Lobby packet types (client <-> server, lobby port) ────────────────────
#define PKT_LIST_REQUEST    25
#define PKT_LIST_RESPONSE   26
#define PKT_JOIN_REQUEST_DB 30
#define PKT_JOIN_RESPONSE   31

// ── Manager packet types (client <-> manager port 9999) ───────────────────
#define PKT_CREATE_REQUEST  50   // client asks manager to spawn a game server
#define PKT_CREATE_ACK      51   // manager replies with assigned port
#define PKT_MANAGER_PING    52   // heartbeat / connectivity check
#define CREATE_OK           0
#define CREATE_NO_PORTS     1

static const uint16_t MANAGER_PORT = 9999;
static const uint16_t PORT_MIN     = 7777;
static const uint16_t PORT_MAX     = 7800;  // 24 simultaneous online lobbies

// ── Join response codes ───────────────────────────────────────────────────
#define JOIN_OK            0
#define JOIN_WRONG_PW      1
#define JOIN_NOT_FOUND     2

using Clock     = std::chrono::steady_clock;
using TimePoint = std::chrono::time_point<Clock>;

// ═══════════════════════════════════════════════════════════════════════════
//  Server state
// ═══════════════════════════════════════════════════════════════════════════

struct Player {
    std::string key;
    sockaddr_in addr;
    uint16_t    pid;
    TimePoint   lastSeen;
    std::string userId;    // Supabase auth user UUID
    std::string username;  // display name
    int         kills  = 0;
    int         deaths = 0;
};

std::map<std::string, Player> players;
uint16_t nextPid      = 1;
bool     matchRunning   = false;
bool     matchJustEnded = false;
TimePoint matchEndTime;
int      matchDuration = 180;
int      timeRemaining = 180;
TimePoint lastTimerBroadcast;

// Supabase IDs for this server instance
int64_t  myLobbyId = -1;
int64_t  myMatchId = -1;
uint16_t myGamePort = 7777;  // set at startup, used by Supabase registration
bool     isLan      = false; // true when launched for LAN hosting

// Server identity (set from argv)
std::string lobbyName;
std::string publicIp;
std::string pwHash;

// ── Auto-detect LAN IP ────────────────────────────────────────────────────
// Connects a UDP socket to a public address (no data sent) and reads back
// the local IP the OS chose — this is the LAN IP on the active interface.
// Works on Windows without enumerating adapters or parsing ipconfig output.
std::string get_lan_ip() {
#ifdef _WIN32
    WSADATA _wsa; WSAStartup(MAKEWORD(2,2), &_wsa);
#endif
    SOCK_T s = socket(AF_INET, SOCK_DGRAM, 0);
    if (s == INVALID_SOCK) return "127.0.0.1";

    sockaddr_in dest{};
    dest.sin_family      = AF_INET;
    dest.sin_port        = htons(80);
    dest.sin_addr.s_addr = inet_addr("8.8.8.8");

    if (connect(s, (sockaddr*)&dest, sizeof(dest)) < 0) {
        CLOSE_SOCK(s);
        return "127.0.0.1";
    }

    sockaddr_in local{};
    socklen_t len = sizeof(local);
    if (getsockname(s, (sockaddr*)&local, &len) < 0) {
        CLOSE_SOCK(s);
        return "127.0.0.1";
    }

    CLOSE_SOCK(s);
    return std::string(inet_ntoa(local.sin_addr));
}

std::string addrKey(const sockaddr_in& a) {
    return std::string(inet_ntoa(a.sin_addr)) + ":" +
           std::to_string(ntohs(a.sin_port));
}

// ═══════════════════════════════════════════════════════════════════════════
//  Packet string helpers
// ═══════════════════════════════════════════════════════════════════════════

int lp_write(char* buf, int off, const std::string& s) {
    uint8_t len = (uint8_t)(s.size() > 63 ? 63 : s.size());
    buf[off] = (char)len;
    memcpy(buf + off + 1, s.c_str(), len);
    return 1 + len;
}

int lp_read(const char* buf, int off, int bufLen, std::string& out) {
    if (off >= bufLen) return 0;
    uint8_t len = (uint8_t)buf[off];
    if (off + 1 + len > bufLen) return 0;
    out = std::string(buf + off + 1, len);
    return 1 + len;
}

// ═══════════════════════════════════════════════════════════════════════════
//  Supabase HTTP helpers
//  Windows: WinHTTP (built-in, no dependencies)
//  Linux:   libcurl (apt install libcurl4-openssl-dev)
// ═══════════════════════════════════════════════════════════════════════════

#ifdef _WIN32

static void parse_url(const std::string& url, std::wstring& host, std::wstring& base) {
    std::string u = url;
    size_t e = u.find("://"); if (e != std::string::npos) u = u.substr(e+3);
    size_t s = u.find('/');
    std::string h = (s==std::string::npos)?u:u.substr(0,s);
    host = std::wstring(h.begin(),h.end());
    base = std::wstring();
}

std::string supabase_request(const std::string& method, const std::string& path,
                              const std::string& body="", const std::string& prefer="") {
    std::wstring host, base;
    parse_url(SUPABASE_URL, host, base);
    std::string fullPathStr = "/rest/v1/" + path;
    std::wstring fullPath(fullPathStr.begin(), fullPathStr.end());
    std::wstring wmethod(method.begin(), method.end());
    std::string result;
    HINTERNET hSess = WinHttpOpen(L"GameServer/1.0",WINHTTP_ACCESS_TYPE_DEFAULT_PROXY,
        WINHTTP_NO_PROXY_NAME,WINHTTP_NO_PROXY_BYPASS,0);
    if (!hSess) return "";
    HINTERNET hConn = WinHttpConnect(hSess,host.c_str(),INTERNET_DEFAULT_HTTPS_PORT,0);
    if (!hConn){WinHttpCloseHandle(hSess);return "";}
    HINTERNET hReq  = WinHttpOpenRequest(hConn,wmethod.c_str(),fullPath.c_str(),
        NULL,WINHTTP_NO_REFERER,WINHTTP_DEFAULT_ACCEPT_TYPES,WINHTTP_FLAG_SECURE);
    if (!hReq){WinHttpCloseHandle(hConn);WinHttpCloseHandle(hSess);return "";}
    DWORD sf=SECURITY_FLAG_IGNORE_UNKNOWN_CA|SECURITY_FLAG_IGNORE_CERT_WRONG_USAGE
            |SECURITY_FLAG_IGNORE_CERT_CN_INVALID|SECURITY_FLAG_IGNORE_CERT_DATE_INVALID;
    WinHttpSetOption(hReq,WINHTTP_OPTION_SECURITY_FLAGS,&sf,sizeof(sf));
    std::wstring key(SUPABASE_KEY,SUPABASE_KEY+strlen(SUPABASE_KEY));
    std::wstring hdrs=L"apikey: "+key+L"\r\nAuthorization: Bearer "+key
                     +L"\r\nContent-Type: application/json\r\n";
    if (!prefer.empty()){std::wstring wp(prefer.begin(),prefer.end());hdrs+=L"Prefer: "+wp+L"\r\n";}
    WinHttpSendRequest(hReq,hdrs.c_str(),(DWORD)-1L,
        body.empty()?WINHTTP_NO_REQUEST_DATA:(LPVOID)body.c_str(),
        (DWORD)body.size(),(DWORD)body.size(),0);
    WinHttpReceiveResponse(hReq,NULL);
    DWORD avail=0;
    while(WinHttpQueryDataAvailable(hReq,&avail)&&avail>0){
        std::string chunk(avail,'\0'); DWORD rd=0;
        WinHttpReadData(hReq,&chunk[0],avail,&rd);
        result.append(chunk,0,rd);
    }
    WinHttpCloseHandle(hReq);WinHttpCloseHandle(hConn);WinHttpCloseHandle(hSess);
    return result;
}

#else  // Linux — libcurl

static size_t curl_write_cb(void* ptr, size_t size, size_t nmemb, std::string* s) {
    s->append((char*)ptr, size * nmemb);
    return size * nmemb;
}

std::string supabase_request(const std::string& method, const std::string& path,
                              const std::string& body="", const std::string& prefer="") {
    CURL* curl = curl_easy_init();
    if (!curl) return "";
    std::string url = std::string(SUPABASE_URL) + "/rest/v1/" + path;
    std::string result;
    struct curl_slist* hdrs = nullptr;
    hdrs = curl_slist_append(hdrs, ("apikey: " + std::string(SUPABASE_KEY)).c_str());
    hdrs = curl_slist_append(hdrs, ("Authorization: Bearer " + std::string(SUPABASE_KEY)).c_str());
    hdrs = curl_slist_append(hdrs, "Content-Type: application/json");
    if (!prefer.empty())
        hdrs = curl_slist_append(hdrs, ("Prefer: " + prefer).c_str());
    curl_easy_setopt(curl, CURLOPT_URL,           url.c_str());
    curl_easy_setopt(curl, CURLOPT_HTTPHEADER,    hdrs);
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, curl_write_cb);
    curl_easy_setopt(curl, CURLOPT_WRITEDATA,     &result);
    curl_easy_setopt(curl, CURLOPT_TIMEOUT,       10L);
    if (method == "POST") {
        curl_easy_setopt(curl, CURLOPT_POST,       1L);
        curl_easy_setopt(curl, CURLOPT_POSTFIELDS, body.c_str());
    } else if (method == "PATCH") {
        curl_easy_setopt(curl, CURLOPT_CUSTOMREQUEST, "PATCH");
        curl_easy_setopt(curl, CURLOPT_POSTFIELDS,    body.c_str());
    } else if (method == "DELETE") {
        curl_easy_setopt(curl, CURLOPT_CUSTOMREQUEST, "DELETE");
    }
    CURLcode res = curl_easy_perform(curl);
    long statusCode = 0;
    curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, &statusCode);
    if (res != CURLE_OK)
        std::cout << "[Supabase] curl error: " << curl_easy_strerror(res) << "\n";
    else if (statusCode > 0 && statusCode != 200 && statusCode != 201)
        std::cout << "[Supabase] " << method << " " << path << " -> HTTP " << statusCode << "\n";
    curl_slist_free_all(hdrs);
    curl_easy_cleanup(curl);
    return result;
}

#endif

// Minimal JSON int64 extractor — finds the first "key":number in a JSON string
// Sufficient for extracting auto-generated IDs from Supabase responses.
int64_t json_extract_int64(const std::string& json, const std::string& key) {
    std::string search = "\"" + key + "\":";
    auto pos = json.find(search);
    if (pos == std::string::npos) return -1;
    pos += search.size();
    while (pos < json.size() && (json[pos] == ' ' || json[pos] == '"')) pos++;
    int64_t val = 0;
    bool neg = (json[pos] == '-');
    if (neg) pos++;
    while (pos < json.size() && isdigit(json[pos]))
        val = val * 10 + (json[pos++] - '0');
    return neg ? -val : val;
}

// Escape a string for embedding in a JSON value
std::string json_str(const std::string& s) {
    std::string out;
    for (char c : s) {
        if (c == '"')  out += "\\\"";
        else if (c == '\\') out += "\\\\";
        else out += c;
    }
    return out;
}

// ═══════════════════════════════════════════════════════════════════════════
//  Supabase lobby/match operations
// ═══════════════════════════════════════════════════════════════════════════

// Called on startup — wipes stale rows, then inserts this lobby
void supabase_register_lobby() {
    // Delete any leftover rows with this host_ip+host_port (from a crashed run)
    supabase_request("DELETE",
        "lobbies?host_ip=eq." + publicIp +
        "&host_port=eq." + std::to_string(GAME_PORT));

    std::string body =
        "{\"lobby_name\":\"" + json_str(lobbyName) + "\","
        "\"host_ip\":\""     + json_str(publicIp)  + "\","
        "\"host_port\":"     + std::to_string(GAME_PORT) + ","
        "\"max_players\":"   + std::to_string(MAX_PLAYERS) + ","
        "\"current_players\":0,"
        "\"password_hash\":"  + (pwHash.empty() ? "null" : "\"" + json_str(pwHash) + "\"") +
        + (isLan ? ",\"is_lan\":true}" : ",\"is_lan\":false}");
        // ^^ is_lan flag for LAN vs online lobbies

    std::string resp = supabase_request("POST", "lobbies", body, "return=representation");
    myLobbyId = json_extract_int64(resp, "id");

    if (myLobbyId > 0)
        std::cout << "Lobby registered in Supabase. ID=" << myLobbyId << "\n";
    else
        std::cout << "WARNING: Supabase lobby registration failed. Response: " << resp << "\n";
}

void supabase_update_players(int count) {
    if (myLobbyId < 0) return;
    supabase_request("PATCH",
        "lobbies?id=eq." + std::to_string(myLobbyId),
        "{\"current_players\":" + std::to_string(count) + "}");
}

void supabase_deregister_lobby() {
    if (myLobbyId < 0) return;
    supabase_request("DELETE", "lobbies?id=eq." + std::to_string(myLobbyId));
    std::cout << "Lobby deregistered from Supabase.\n";
    myLobbyId = -1;
}

void supabase_set_active(bool active) {
    if (myLobbyId < 0) return;
    std::string body = active
        ? "{\"is_active\":true,\"match_id\":"  + std::to_string(myMatchId) + "}"
        : "{\"is_active\":false,\"match_id\":null}";
    supabase_request("PATCH",
        "lobbies?id=eq." + std::to_string(myLobbyId), body);
}

void supabase_match_start() {
    // 1. Insert match row
    std::string body = "{\"lobby_id\":" + std::to_string(myLobbyId) + "}";
    std::string resp = supabase_request("POST", "matches", body, "return=representation");
    myMatchId = json_extract_int64(resp, "id");
    std::cout << "Match created in Supabase. ID=" << myMatchId << "\n";

    // 2. Insert match_players rows
    for (auto& pair : players) {
        uint16_t pid = pair.second.pid;
        std::string dname = "Player" + std::to_string(pid);

        // Find or create player record
        std::string prsp = supabase_request("GET",
            "players?pid=eq." + std::to_string(pid) + "&limit=1",
            "", "return=representation");
        int64_t playerId = json_extract_int64(prsp, "id");
        if (playerId < 0) {
            std::string pb = "{\"pid\":" + std::to_string(pid) +
                             ",\"display_name\":\"" + json_str(dname) + "\"}";
            std::string pr2 = supabase_request("POST", "players", pb, "return=representation");
            playerId = json_extract_int64(pr2, "id");
        }

        // Insert match_players row
        if (playerId > 0) {
            std::string mpb =
                "{\"match_id\":"  + std::to_string(myMatchId) +
                ",\"player_id\":" + std::to_string(playerId) +
                ",\"pid\":"       + std::to_string(pid) + "}";
            supabase_request("POST", "match_players", mpb);
        }
    }

    supabase_set_active(true);
}

void supabase_record_kill(uint16_t killerPid, uint16_t victimPid) {
    if (myMatchId < 0) return;
    // Increment killer kills
    supabase_request("PATCH",
        "match_players?match_id=eq." + std::to_string(myMatchId) +
        "&pid=eq." + std::to_string(killerPid),
        "{\"kills\":\"kills + 1\"}");
    // Increment victim deaths
    supabase_request("PATCH",
        "match_players?match_id=eq." + std::to_string(myMatchId) +
        "&pid=eq." + std::to_string(victimPid),
        "{\"deaths\":\"deaths + 1\"}");

    std::cout << "Kill recorded: " << killerPid << " -> " << victimPid << "\n";
}

void supabase_update_profile(const std::string& userId, int kills, int deaths, int won) {
    if (userId.empty()) return;  // guest player — no profile to update
    std::string body =
        "{\"p_user_id\":\"" + json_str(userId) + "\","
        "\"kills_inc\":"  + std::to_string(kills)  + ","
        "\"deaths_inc\":" + std::to_string(deaths) + ","
        "\"wins_inc\":"   + std::to_string(won)    + "}";
    std::string resp = supabase_request("POST", "rpc/increment_player_stats", body);
    std::cout << "Profile updated: uid=" << userId
              << " K=" << kills << " D=" << deaths << " W=" << won << "\n";
}

void supabase_match_end() {
    if (myMatchId < 0) return;
    supabase_request("PATCH",
        "matches?id=eq." + std::to_string(myMatchId),
        "{\"ended_at\":\"now()\"}");
    supabase_set_active(false);
    std::cout << "Match " << myMatchId << " ended in Supabase.\n";
    myMatchId = -1;
}

// ═══════════════════════════════════════════════════════════════════════════
//  Lobby list — fetched from Supabase and sent to requesting clients
// ═══════════════════════════════════════════════════════════════════════════

// Parse a JSON array of lobby objects from Supabase and send as type-26 packet
void send_lobby_list(int sock, const sockaddr_in& dest) {
    // Fetch all lobbies from Supabase
    std::string resp = supabase_request("GET",
        "lobbies?select=id,lobby_name,host_ip,host_port,current_players,"
        "max_players,password_hash,is_active,is_lan&order=id");

    // Very simple JSON array parser — extracts field values sequentially
    // Works correctly with the flat JSON Supabase returns for this schema
    struct LobbyRow {
        int64_t     id;
        std::string name, ip;
        uint16_t    port;
        uint8_t     cur, max, hasPw, active, lan;
    };
    std::vector<LobbyRow> rows;

    // Parse each {...} object in the array
    size_t pos = 0;
    while ((pos = resp.find('{', pos)) != std::string::npos) {
        LobbyRow r{};
        auto end = resp.find('}', pos);
        if (end == std::string::npos) break;
        std::string obj = resp.substr(pos, end - pos + 1);
        pos = end + 1;

        r.id     = json_extract_int64(obj, "id");
        r.cur    = (uint8_t)json_extract_int64(obj, "current_players");
        r.max    = (uint8_t)json_extract_int64(obj, "max_players");
        r.port   = (uint16_t)json_extract_int64(obj, "host_port");
        r.hasPw  = (obj.find("\"password_hash\":null") == std::string::npos) ? 1 : 0;
        r.active = (obj.find("\"is_active\":true") != std::string::npos) ? 1 : 0;
        r.lan    = (obj.find("\"is_lan\":true")    != std::string::npos) ? 1 : 0;

        // Extract string fields
        auto extract_str = [&](const std::string& key) -> std::string {
            std::string search = "\"" + key + "\":\"";
            auto p = obj.find(search);
            if (p == std::string::npos) return "";
            p += search.size();
            auto e = obj.find('"', p);
            return (e == std::string::npos) ? "" : obj.substr(p, e - p);
        };
        r.name = extract_str("lobby_name");
        r.ip   = extract_str("host_ip");

        if (r.id > 0 && !r.name.empty()) rows.push_back(r);
    }
    if (rows.size() > 20) rows.resize(20);

    // Build type-26 packet
    char buf[1400];
    int off = 0;
    buf[off++] = PKT_LIST_RESPONSE;
    buf[off++] = (uint8_t)rows.size();
    for (auto& r : rows) {
        // id as two u16s
        uint16_t id_lo = (uint16_t)(r.id & 0xFFFF);
        uint16_t id_hi = (uint16_t)((r.id >> 16) & 0xFFFF);
        memcpy(buf + off, &id_lo, 2); off += 2;
        memcpy(buf + off, &id_hi, 2); off += 2;
        off += lp_write(buf, off, r.name);
        off += lp_write(buf, off, r.ip);    // client discards this but must read it
        memcpy(buf + off, &r.port, 2); off += 2;
        buf[off++] = r.cur;
        buf[off++] = r.max;
        buf[off++] = r.hasPw;
        buf[off++] = r.active;
        buf[off++] = r.lan;
    }
    sendto(sock, buf, off, 0, (const sockaddr*)&dest, sizeof(dest));
    std::cout << "Sent lobby list (" << rows.size() << ") to "
              << inet_ntoa(dest.sin_addr) << "\n";
}

// Handle a client join request — validate password, return host address
void handle_join_request(int sock, const sockaddr_in& src,
                          int64_t lobbyId, bool hasPw, const std::string& clientPwHash) {
    char reply[128];
    int off = 0;
    reply[off++] = PKT_JOIN_RESPONSE;

    // Fetch lobby from Supabase
    std::string resp = supabase_request("GET",
        "lobbies?id=eq." + std::to_string(lobbyId) +
        "&select=host_ip,host_port,password_hash&limit=1");

    if (resp.find("host_ip") == std::string::npos) {
        reply[off++] = JOIN_NOT_FOUND;
        sendto(sock, reply, off, 0, (const sockaddr*)&src, sizeof(src));
        return;
    }

    // Extract fields
    auto extract_str = [&](const std::string& key) -> std::string {
        std::string search = "\"" + key + "\":\"";
        auto p = resp.find(search);
        if (p == std::string::npos) return "";
        p += search.size();
        auto e = resp.find('"', p);
        return (e == std::string::npos) ? "" : resp.substr(p, e - p);
    };

    std::string hostIp   = extract_str("host_ip");
    uint16_t    hostPort = (uint16_t)json_extract_int64(resp, "host_port");
    bool        dbHasPw  = (resp.find("\"password_hash\":null") == std::string::npos);
    std::string dbPwHash = dbHasPw ? extract_str("password_hash") : "";

    if (dbHasPw && (!hasPw || clientPwHash != dbPwHash)) {
        reply[off++] = JOIN_WRONG_PW;
        sendto(sock, reply, off, 0, (const sockaddr*)&src, sizeof(src));
        std::cout << "Join denied (wrong pw) lobby " << lobbyId << "\n";
        return;
    }

    reply[off++] = JOIN_OK;
    off += lp_write(reply, off, hostIp);
    memcpy(reply + off, &hostPort, 2); off += 2;
    sendto(sock, reply, off, 0, (const sockaddr*)&src, sizeof(src));
    std::cout << "Join approved: lobby " << lobbyId
              << " -> " << hostIp << ":" << hostPort << "\n";
}

// ═══════════════════════════════════════════════════════════════════════════
//  Game packet helpers
// ═══════════════════════════════════════════════════════════════════════════

void broadcast(int sock, const char* buf, int len, const std::string& excludeKey) {
    for (auto& p : players) {
        if (p.first == excludeKey) continue;
        sendto(sock, buf, len, 0,
               (sockaddr*)&p.second.addr, sizeof(p.second.addr));
    }
}

void broadcast_player_left(int sock, uint16_t pid, const std::string& excludeKey) {
    char msg[3]; msg[0] = PKT_PLAYER_LEFT;
    memcpy(msg + 1, &pid, 2);
    broadcast(sock, msg, 3, excludeKey);
}

void reset_lobby() {
    nextPid      = 1;
    matchRunning = false;
    std::cout << "Lobby empty — pid counter reset.\n";
}

// ═══════════════════════════════════════════════════════════════════════════
//  Manager mode  (Linux / Droplet only)
//
//  Usage:  ./server --manager <public_ip>
//
//  Listens on UDP port 9999. When a client sends a type-50 CREATE_LOBBY
//  request, forks a new ./server child process on the next available port
//  (7777-7800) and replies with type-51 ACK containing the assigned port.
//  The client then polls that port with type-255 pings until the child
//  server responds, then transitions to rLobby as the host.
// ═══════════════════════════════════════════════════════════════════════════

#ifndef _WIN32
#include <sys/wait.h>
#include <signal.h>

void run_as_manager(const std::string& dropletIp) {
    std::map<uint16_t, pid_t> portInUse;

    // Manager socket — handles create requests on port 9999
    int sock = socket(AF_INET, SOCK_DGRAM, 0);
    sockaddr_in addr{};
    addr.sin_family      = AF_INET;
    addr.sin_port        = htons(MANAGER_PORT);
    addr.sin_addr.s_addr = INADDR_ANY;
    if (bind(sock, (sockaddr*)&addr, sizeof(addr)) < 0) {
        std::cerr << "Manager: bind failed on port " << MANAGER_PORT << "\n";
        return;
    }

    // Lobby socket — handles list/join requests on port 8888
    int lobbySock = socket(AF_INET, SOCK_DGRAM, 0);
    sockaddr_in lobbyAddr{};
    lobbyAddr.sin_family      = AF_INET;
    lobbyAddr.sin_port        = htons(LOBBY_PORT);
    lobbyAddr.sin_addr.s_addr = INADDR_ANY;
    if (bind(lobbySock, (sockaddr*)&lobbyAddr, sizeof(lobbyAddr)) < 0) {
        std::cerr << "Manager: bind failed on lobby port " << LOBBY_PORT
                  << " errno=" << errno << " (" << strerror(errno) << ")\n";
        return;
    }
    std::cout << "Manager: lobby socket bound to port " << LOBBY_PORT << "\n";

    // Set both sockets non-blocking for drain loops
    fcntl(sock,      F_SETFL, O_NONBLOCK);
    fcntl(lobbySock, F_SETFL, O_NONBLOCK);

    std::cout << "=== Lobby Manager ===\n"
              << "  Manager port : " << MANAGER_PORT << "\n"
              << "  Lobby port   : " << LOBBY_PORT << "\n"
              << "  Public IP    : " << dropletIp << "\n"
              << "  Port pool    : " << PORT_MIN << "-" << PORT_MAX << "\n"
              << "=====================\n";

    char buf[1500];
    sockaddr_in src{};
    socklen_t srcLen = sizeof(src);

    while (true) {
        // Reap finished game server processes and free their ports
        int status;
        pid_t dead;
        while ((dead = waitpid(-1, &status, WNOHANG)) > 0) {
            for (auto it = portInUse.begin(); it != portInUse.end(); ++it) {
                if (it->second == dead) {
                    std::cout << "Server on port " << it->first
                              << " exited (pid=" << dead << ")\n";
                    portInUse.erase(it);
                    break;
                }
            }
        }

        // Use select() to monitor both sockets simultaneously
        fd_set fds;
        FD_ZERO(&fds);
        FD_SET(sock,      &fds);
        FD_SET(lobbySock, &fds);
        int maxfd = std::max(sock, lobbySock) + 1;
        struct timeval stv; stv.tv_sec = 1; stv.tv_usec = 0;
        int ready = select(maxfd, &fds, nullptr, nullptr, &stv);
        if (ready <= 0) continue;

        // ── Drain lobby socket first (list/join requests) ────────────
        if (FD_ISSET(lobbySock, &fds)) {
            char lbuf[512];
            sockaddr_in lsrc{};
            socklen_t lsrcLen = sizeof(lsrc);
            while (true) {
                int lbytes = recvfrom(lobbySock, lbuf, sizeof(lbuf) - 1, 0,
                                      (sockaddr*)&lsrc, &lsrcLen);
                if (lbytes <= 0) break;
                uint8_t ltype = (uint8_t)lbuf[0];
                std::cout << "Manager lobby recv: type=" << (int)ltype
                          << " from " << inet_ntoa(lsrc.sin_addr) << "\n";
                if (ltype == PKT_LIST_REQUEST) {
                    send_lobby_list(lobbySock, lsrc);
                } else if (ltype == PKT_JOIN_REQUEST_DB && lbytes >= 6) {
                    uint16_t id_lo, id_hi;
                    memcpy(&id_lo, lbuf + 1, 2);
                    memcpy(&id_hi, lbuf + 3, 2);
                    int64_t lobbyId = (int64_t)id_lo | ((int64_t)id_hi << 16);
                    uint8_t hasPw   = (uint8_t)lbuf[5];
                    std::string cpw;
                    if (hasPw) lp_read(lbuf, 6, lbytes, cpw);
                    handle_join_request(lobbySock, lsrc, lobbyId, hasPw != 0, cpw);
                }
            }
        }

        // ── Drain manager socket (create requests) ───────────────────
        if (!FD_ISSET(sock, &fds)) continue;

        int bytes = recvfrom(sock, buf, sizeof(buf) - 1, 0,
                             (sockaddr*)&src, &srcLen);
        if (bytes <= 0) continue;

        uint8_t type = (uint8_t)buf[0];

        // 52 — ping, echo back
        if (type == PKT_MANAGER_PING) {
            char pong[1] = { PKT_MANAGER_PING };
            sendto(sock, pong, 1, 0, (sockaddr*)&src, srcLen);
            continue;
        }

        // 50 — create lobby request
        if (type == PKT_CREATE_REQUEST && bytes >= 2) {
            std::string lobbyName, pwHash;
            int off = 1;
            // read lobby name
            if (off < bytes) {
                uint8_t nlen = (uint8_t)buf[off++];
                for (int i = 0; i < nlen && off < bytes; i++)
                    lobbyName += (char)buf[off++];
            }
            // read password flag + hash
            uint8_t hasPw = (off < bytes) ? (uint8_t)buf[off++] : 0;
            if (hasPw && off < bytes) {
                uint8_t plen = (uint8_t)buf[off++];
                for (int i = 0; i < plen && off < bytes; i++)
                    pwHash += (char)buf[off++];
            }

            std::cout << "Create request: \"" << lobbyName << "\""
                      << " from " << inet_ntoa(src.sin_addr) << "\n";

            // Find next free port
            uint16_t port = 0;
            for (uint16_t p = PORT_MIN; p <= PORT_MAX; p++) {
                if (portInUse.find(p) == portInUse.end()) { port = p; break; }
            }

            char reply[4];
            reply[0] = PKT_CREATE_ACK;

            if (port == 0) {
                std::cout << "No ports available.\n";
                reply[1] = CREATE_NO_PORTS;
                sendto(sock, reply, 2, 0, (sockaddr*)&src, srcLen);
                continue;
            }

            // Fork a game server child
            pid_t pid = fork();
            if (pid == 0) {
                // Child: exec the same binary in game-server mode
                std::string portStr = std::to_string(port);
                if (pwHash.empty())
                    execl("/proc/self/exe", "server",
                          lobbyName.c_str(), dropletIp.c_str(),
                          portStr.c_str(), (char*)nullptr);
                else
                    execl("/proc/self/exe", "server",
                          lobbyName.c_str(), dropletIp.c_str(),
                          portStr.c_str(), pwHash.c_str(), (char*)nullptr);
                std::cerr << "execl failed\n";
                _exit(1);
            }

            if (pid < 0) {
                std::cerr << "fork() failed\n";
                reply[1] = CREATE_NO_PORTS;
                sendto(sock, reply, 2, 0, (sockaddr*)&src, srcLen);
                continue;
            }

            portInUse[port] = pid;
            std::cout << "Spawned server \"" << lobbyName
                      << "\" on port " << port
                      << " (pid=" << pid << ")\n";

            reply[1] = CREATE_OK;
            memcpy(reply + 2, &port, 2);
            sendto(sock, reply, 4, 0, (sockaddr*)&src, srcLen);
        }
    }

    close(sock);
    close(lobbySock);
}
#endif  // !_WIN32

// ═══════════════════════════════════════════════════════════════════════════
//  main
// ═══════════════════════════════════════════════════════════════════════════

int main(int argc, char* argv[]) {
#ifdef _WIN32
    WSADATA _wsa; WSAStartup(MAKEWORD(2,2), &_wsa);
#else
    curl_global_init(CURL_GLOBAL_ALL);
#endif

    // ── Manager mode ─────────────────────────────────────────────────────
    // Usage:  ./server --manager <public_ip>
    // Runs the lobby manager instead of a game server instance.
#ifndef _WIN32
    if (argc >= 3 && std::string(argv[1]) == "--manager") {
        run_as_manager(argv[2]);
        return 0;
    }
#endif

    std::cout << "server.exe argc=" << argc << "\n";
    for (int i = 1; i < argc; i++)
        std::cout << "  argv[" << i << "] = \"" << argv[i] << "\"\n";
    std::cout << std::flush;

    if (argc < 2) {
        std::cerr
            << "\nUsage (game server): server <lobby_name> [public_ip] [port] [password_hash]\n"
            << "Usage (manager):     server --manager <public_ip>\n\n"
            << "Examples:\n"
            << "  server \"My Lobby\"                    (LAN — auto-detects IP)\n"
            << "  server --manager 203.0.113.10         (Droplet manager mode)\n";
        return 1;
    }

    lobbyName = argv[1];

    // Detect LAN IP — on Droplet this is the public IP, on home PC it's LAN IP
    std::string detectedIp = get_lan_ip();

    // Parse remaining args: [public_ip] [port] [password_hash]
    // Manager passes: <name> <public_ip> <port> [pw_hash]
    // GML LAN passes: <name> [pw_hash]
    // All args after name are classified by content:
    //   contains dot      → IP override
    //   all digits        → port override
    //   anything else     → password hash
    uint16_t portOverride = 0;
    for (int i = 2; i < argc; i++) {
        std::string a = argv[i];
        if (a == "--lan") {
            isLan = true;
        } else if (a.find('.') != std::string::npos) {
            publicIp = a;
        } else if (!a.empty() && a.find_first_not_of("0123456789") == std::string::npos) {
            portOverride = (uint16_t)std::stoi(a);
        } else {
            pwHash = a;
        }
    }
    if (publicIp.empty()) publicIp = detectedIp;

    std::cout << "LAN IP detected: " << detectedIp << "\n";
    if (publicIp != detectedIp)
        std::cout << "Using override IP: " << publicIp << "\n";
    if (portOverride > 0)
        std::cout << "Port override: " << portOverride << "\n";

    auto make_udp_sock = [](uint16_t port, int timeoutMs) -> int {
        int s = (int)socket(AF_INET, SOCK_DGRAM, 0);
        if (s < 0) return s;
        sockaddr_in addr{};
        addr.sin_family      = AF_INET;
        addr.sin_port        = htons(port);
        addr.sin_addr.s_addr = INADDR_ANY;
        if (bind(s, (sockaddr*)&addr, sizeof(addr)) < 0) {
            std::cerr << "Bind failed on port " << port
                      << " (WSA " << errno << ")\n"
                      << "Is another instance already running?\n";
            exit(1);
        }
#ifdef _WIN32
        DWORD tv = (DWORD)timeoutMs;
        setsockopt(s, SOL_SOCKET, SO_RCVTIMEO, SOCKOPT_CAST &tv, sizeof(tv));
#else
        struct timeval tv; tv.tv_sec = timeoutMs/1000; tv.tv_usec = (timeoutMs%1000)*1000;
        setsockopt(s, SOL_SOCKET, SO_RCVTIMEO, SOCKOPT_CAST &tv, sizeof(tv));
#endif
        return s;
    };

    uint16_t gamePort  = (portOverride > 0) ? portOverride : GAME_PORT;
    myGamePort = gamePort;
    // Manager-spawned instances (portOverride > 0) don't bind the lobby port —
    // the manager handles all list/join requests on port 8888.
    // LAN host (no port override) binds lobby port normally.
    uint16_t lobbyPort = (portOverride > 0) ? 0 : LOBBY_PORT;
    int gameSock  = make_udp_sock(gamePort, 1);
    // For spawned instances, create a plain unbound socket — won't receive anything
    // but keeps the drain loop code from crashing on an invalid fd.
#ifdef _WIN32
    int lobbySock = (lobbyPort > 0) ? make_udp_sock(lobbyPort, 1) : (int)socket(AF_INET, SOCK_DGRAM, 0);
#else
    int lobbySock = (lobbyPort > 0) ? make_udp_sock(lobbyPort, 1) : socket(AF_INET, SOCK_DGRAM, 0);
    // Set unbound lobby socket non-blocking so drain loop returns immediately
    if (lobbyPort == 0) fcntl(lobbySock, F_SETFL, O_NONBLOCK);
#endif

    // No broadcast socket needed — discovery is request/reply based

    // ── Register lobby in Supabase ────────────────────────────────────────
    // Retry up to 5 times with 1s delay — child processes sometimes need
    // a moment for DNS to become available after fork+exec on Linux.
    for (int _attempt = 1; _attempt <= 5; _attempt++) {
        supabase_register_lobby();
        if (myLobbyId > 0) break;
        std::cout << "Supabase registration attempt " << _attempt
                  << " failed, retrying in 1s...\n";
        sleep(1);
    }

    std::cout << "\n=== Server Ready ===\n"
              << "  Lobby    : " << lobbyName << "\n"
              << "  Game port: " << gamePort  << "\n"
              << "  Lobby port: " << lobbyPort << "\n"
              << "  Public IP: " << publicIp   << "\n"
              << "  Password : " << (pwHash.empty() ? "none" : "set") << "\n"
              << "===================\n\n" << std::flush;

    char     gameBuf[512];
    char     lobbyBuf[1024];
    sockaddr_in src{};
    socklen_t srcLen = sizeof(src);

    lastTimerBroadcast = Clock::now();

    TimePoint lastPlayerCountUpdate = Clock::now();

    while (true) {
        auto now = Clock::now();


        // ── Periodic player count sync to Supabase (every 5s) ────────────
        if (std::chrono::duration_cast<std::chrono::seconds>(
                now - lastPlayerCountUpdate).count() >= 5) {
            lastPlayerCountUpdate = now;
            supabase_update_players((int)players.size());
        }

        // ── Timeout stale game clients ────────────────────────────────────
        bool hostTimedOut = false;
        for (auto it = players.begin(); it != players.end(); ) {
            auto age = std::chrono::duration_cast<std::chrono::seconds>(
                           now - it->second.lastSeen).count();
            if (age > TIMEOUT_S) {
                std::cout << "Timeout: " << it->first << "\n";
                if (it->second.pid == 1) hostTimedOut = true;
                broadcast_player_left(gameSock, it->second.pid, it->first);
                it = players.erase(it);
            } else ++it;
        }
        if (hostTimedOut) {
            std::cout << "Host timed out — deleting lobby and shutting down.\n";
            supabase_deregister_lobby();
            goto shutdown;
        }
        if (players.empty() && nextPid != 1) reset_lobby();

        // ── Match timer ───────────────────────────────────────────────────
        if (matchRunning) {
            auto elapsed = std::chrono::duration_cast<std::chrono::seconds>(
                               now - lastTimerBroadcast).count();
            if (elapsed >= 1) {
                lastTimerBroadcast = now;
                if (--timeRemaining <= 0) {
                    timeRemaining = 0;
                    matchRunning  = false;
                    std::cout << "Match over!\n";
                    char ep[1] = { PKT_MATCH_END_BC };
                    broadcast(gameSock, ep, 1, "");
                    supabase_match_end();
                    // Update cumulative profile stats for each player
                    // Determine winner: player with most kills
                    uint16_t topPid = 0; int topKills = -1;
                    for (auto& pr : players) {
                        if (pr.second.kills > topKills) {
                            topKills = pr.second.kills;
                            topPid   = pr.second.pid;
                        }
                    }
                    for (auto& pr : players) {
                        int won = (pr.second.pid == topPid) ? 1 : 0;
                        supabase_update_profile(
                            pr.second.userId,
                            pr.second.kills,
                            pr.second.deaths,
                            won);
                        std::cout << "Stats: " << pr.second.username
                                  << " K=" << pr.second.kills
                                  << " D=" << pr.second.deaths
                                  << " W=" << won << "\n";
                    }
                    matchJustEnded = true;
                    matchEndTime   = Clock::now();
                }
                char tp[3]; tp[0] = PKT_TIMER;
                uint16_t t = (uint16_t)timeRemaining;
                memcpy(tp + 1, &t, 2);
                broadcast(gameSock, tp, 3, "");
            }
        }

        // ── Post-match reset ──────────────────────────────────────────
        // After match ends, wait 1 second then clear player list so
        // returning players re-register cleanly with fresh pids.
        if (matchJustEnded) {
            auto sinceEnd = std::chrono::duration_cast<std::chrono::milliseconds>(
                                Clock::now() - matchEndTime).count();
            if (sinceEnd >= 2000) {
                players.clear();
                nextPid        = 1;
                matchJustEnded = false;
                std::cout << "Lobby reset — ready for next match.\n";
            }
        }

        // ── Drain game socket ─────────────────────────────────────────────
        while (true) {
            int bytes = recvfrom(gameSock, gameBuf, sizeof(gameBuf) - 1, 0,
                                 (sockaddr*)&src, &srcLen);
            if (bytes <= 0) break;

            std::string key  = addrKey(src);
            uint8_t     type = (uint8_t)gameBuf[0];

            // 41 discovery ping — reply with lobby info directly to sender
            if (type == PKT_DISCOVERY_PING) {
                char disc[128]; int doff = 0;
                disc[doff++] = PKT_DISCOVERY;
                doff += lp_write(disc, doff, lobbyName);
                disc[doff++] = (uint8_t)players.size();
                disc[doff++] = MAX_PLAYERS;
                disc[doff++] = pwHash.empty() ? 0 : 1;
                sendto(gameSock, disc, doff, 0, (sockaddr*)&src, srcLen);
                std::cout << "Discovery ping from " << addrKey(src) << " -> replied\n";
                continue;
            }

            // 255 ping — echo, no registration
            if (type == 255) {
                char pong[1] = { (char)255 };
                sendto(gameSock, pong, 1, 0, (sockaddr*)&src, srcLen);
                continue;
            }

            // 12 keepalive
            if (type == PKT_KEEPALIVE) {
                if (players.count(key)) players[key].lastSeen = Clock::now();
                continue;
            }

            // 9 disconnect
            if (type == PKT_DISCONNECT) {
                if (players.count(key)) {
                    uint16_t leavingPid = players[key].pid;
                    std::cout << "Disconnect: " << key << " pid=" << leavingPid << "\n";
                    broadcast_player_left(gameSock, leavingPid, key);
                    players.erase(key);
                    supabase_update_players((int)players.size());
                    if (leavingPid == 1) {
                        // Host left — delete lobby and shut down
                        std::cout << "Host disconnected — deleting lobby and shutting down.\n";
                        supabase_deregister_lobby();
                        goto shutdown;
                    }
                    if (players.empty()) reset_lobby();
                }
                continue;
            }

            // Register new player
            if (!players.count(key)) {
                if ((int)players.size() >= MAX_PLAYERS) {
                    std::cout << "Lobby full, rejecting: " << key << "\n";
                    continue;
                }
                // Read optional user_id and username from join packet
                // Packet: [u8:10][lpstr:user_id][lpstr:username]
                std::string joinUserId, joinUsername;
                if (bytes > 1) lp_read(gameBuf, 1, bytes, joinUserId);
                int unOff = 1 + (joinUserId.empty() ? 1 : 1 + (int)joinUserId.size());
                if (unOff < bytes) lp_read(gameBuf, unOff, bytes, joinUsername);
                if (joinUsername.empty()) joinUsername = "Player";

                Player p;
                p.key      = key;
                p.addr     = src;
                p.pid      = nextPid++;
                p.lastSeen = Clock::now();
                p.userId   = joinUserId;
                p.username = joinUsername;
                p.kills    = 0;
                p.deaths   = 0;
                players[key] = p;

                uint16_t pid = players[key].pid;
                std::cout << (pid == 1 ? "HOST" : "Player")
                          << " registered: " << key
                          << " pid=" << pid
                          << " user=" << joinUsername
                          << " uid=" << joinUserId << "\n";
                char ja[3]; ja[0] = PKT_ID_ASSIGN;
                memcpy(ja + 1, &pid, 2);
                sendto(gameSock, ja, 3, 0, (sockaddr*)&src, srcLen);
                supabase_update_players((int)players.size());
            }
            players[key].lastSeen = Clock::now();

            // 1 player state
            if (type == PKT_PLAYER_STATE) {
                uint16_t spid = players[key].pid;
                char bc[512]; bc[0] = PKT_PLAYER_STATE;
                memcpy(bc + 1, &spid, 2);
                memcpy(bc + 3, gameBuf + 1, bytes - 1);
                broadcast(gameSock, bc, bytes + 2, key);
            }

            // 4 bullet
            if (type == PKT_BULLET) {
                uint16_t spid = players[key].pid;
                char bc[512]; bc[0] = PKT_BULLET;
                memcpy(bc + 1, &spid, 2);
                memcpy(bc + 3, gameBuf + 1, bytes - 1);
                broadcast(gameSock, bc, bytes + 2, key);
            }

            // 7 match start
            if (type == PKT_MATCH_START) {
                uint16_t pid = players[key].pid;
                std::cout << "Match start requested by pid=" << pid << "\n";
                if (pid != 1) {
                    std::cout << "Non-host ignored.\n"; continue;
                }
                if ((int)players.size() < 2) {
                    std::cout << "Not enough players.\n";
                    char ne[1] = { PKT_NOT_ENOUGH };
                    sendto(gameSock, ne, 1, 0, (sockaddr*)&src, srcLen);
                    continue;
                }
                matchRunning       = true;
                timeRemaining      = matchDuration;
                lastTimerBroadcast = Clock::now();
                std::cout << "Match started!\n";
                char sp[1] = { PKT_MATCH_START };
                broadcast(gameSock, sp, 1, "");
                supabase_match_start();
            }

            // 10 join request
            if (type == PKT_JOIN_REQUEST && players.count(key)) {
                uint16_t pid = players[key].pid;
                char ja[3]; ja[0] = PKT_ID_ASSIGN;
                memcpy(ja + 1, &pid, 2);
                sendto(gameSock, ja, 3, 0, (sockaddr*)&src, srcLen);
            }

            // 11 kill report
            if (type == PKT_KILL_REPORT && bytes >= 5 && matchRunning) {
                uint16_t killer, victim;
                memcpy(&killer, gameBuf + 1, 2);
                memcpy(&victim, gameBuf + 3, 2);
                if (killer == players[key].pid)
                    supabase_record_kill(killer, victim);
            }
        } // end game drain loop

        // ── Drain lobby socket ────────────────────────────────────────────
        while (true) {
            int bytes = recvfrom(lobbySock, lobbyBuf, sizeof(lobbyBuf) - 1, 0,
                                 (sockaddr*)&src, &srcLen);
            if (bytes <= 0) break;

            uint8_t type = (uint8_t)lobbyBuf[0];

            // 25 list request
            if (type == PKT_LIST_REQUEST) {
                send_lobby_list(lobbySock, src);
            }

            // 30 join request
            if (type == PKT_JOIN_REQUEST_DB && bytes >= 6) {
                uint16_t id_lo, id_hi;
                memcpy(&id_lo, lobbyBuf + 1, 2);
                memcpy(&id_hi, lobbyBuf + 3, 2);
                int64_t lobbyId = (int64_t)id_lo | ((int64_t)id_hi << 16);
                uint8_t hasPw   = (uint8_t)lobbyBuf[5];
                std::string cpw;
                if (hasPw) lp_read(lobbyBuf, 6, bytes, cpw);
                handle_join_request(lobbySock, src, lobbyId, hasPw != 0, cpw);
            }
        } // end lobby drain loop

    } // end main loop

shutdown:
    supabase_deregister_lobby();
#ifdef _WIN32
    closesocket(gameSock); closesocket(lobbySock);
    WSACleanup();
#else
    close(gameSock); close(lobbySock);
    curl_global_cleanup();
#endif
    return 0;
}
