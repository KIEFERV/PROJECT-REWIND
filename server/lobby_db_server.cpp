/*
 * lobby_db_server.cpp  —  v2
 *
 * Standalone lobby + stats database server.
 * Runs on its own dedicated machine. Both game servers and game clients connect to it.
 *
 * ════════════════════════════════════════════════════════════════════════════
 *  DATABASE SCHEMA
 * ════════════════════════════════════════════════════════════════════════════
 *
 *  lobbies
 *  ───────────────────────────────────────────────────────────────────────
 *  id              INTEGER  PK AUTOINCREMENT
 *  lobby_name      TEXT     NOT NULL
 *  host_ip         TEXT     NOT NULL
 *  host_port       INTEGER  NOT NULL
 *  max_players     INTEGER  NOT NULL
 *  current_players INTEGER  DEFAULT 0
 *  password_hash   TEXT     DEFAULT NULL   (NULL = no password required)
 *  is_active       INTEGER  DEFAULT 0      (0 = waiting, 1 = match running)
 *  match_id        INTEGER  DEFAULT NULL   (FK → matches.id once started)
 *  created_at      DATETIME DEFAULT CURRENT_TIMESTAMP
 *
 *  matches
 *  ───────────────────────────────────────────────────────────────────────
 *  id              INTEGER  PK AUTOINCREMENT
 *  lobby_id        INTEGER  NOT NULL
 *  started_at      DATETIME DEFAULT CURRENT_TIMESTAMP
 *  ended_at        DATETIME DEFAULT NULL
 *
 *  players
 *  ───────────────────────────────────────────────────────────────────────
 *  id              INTEGER  PK AUTOINCREMENT
 *  pid             INTEGER  NOT NULL     (in-session pid from game server)
 *  display_name    TEXT     DEFAULT 'Player'
 *  created_at      DATETIME DEFAULT CURRENT_TIMESTAMP
 *
 *  match_players   (one row per player per match — stores kills & deaths)
 *  ───────────────────────────────────────────────────────────────────────
 *  id              INTEGER  PK AUTOINCREMENT
 *  match_id        INTEGER  NOT NULL REFERENCES matches(id)
 *  player_id       INTEGER  NOT NULL REFERENCES players(id)
 *  pid             INTEGER  NOT NULL     (in-session pid, for fast lookup)
 *  kills           INTEGER  DEFAULT 0
 *  deaths          INTEGER  DEFAULT 0
 *
 * ════════════════════════════════════════════════════════════════════════════
 *  PACKET PROTOCOL   (UDP, little-endian, strings are length-prefixed)
 * ════════════════════════════════════════════════════════════════════════════
 *
 *  String encoding:  [u8:length][bytes…]  max 63 chars.
 *
 *  ── game server → DB server ──────────────────────────────────────────────
 *
 *  20  REGISTER
 *        [u8:20][lpstr:name][lpstr:host_ip][u16:port][u8:max_players]
 *        [u8:has_password]  if has_password: [lpstr:password_hash]
 *        reply: type 21
 *
 *  22  UPDATE_PLAYERS
 *        [u8:22][u32:lobby_id][u8:current_players]
 *
 *  23  DEREGISTER
 *        [u8:23][u32:lobby_id]
 *
 *  24  HEARTBEAT
 *        [u8:24][u32:lobby_id]
 *
 *  27  MATCH_START
 *        [u8:27][u32:lobby_id][u8:player_count]
 *        then for each player: [u16:pid][lpstr:display_name]
 *        reply: type 28
 *
 *  32  KILL_EVENT
 *        [u8:32][u32:match_id][u16:killer_pid][u16:victim_pid]
 *
 *  33  MATCH_END
 *        [u8:33][u32:match_id][u32:lobby_id]
 *
 *  ── DB server → game server ──────────────────────────────────────────────
 *
 *  21  REGISTER_ACK
 *        [u8:21][u32:lobby_id]
 *
 *  28  MATCH_START_ACK
 *        [u8:28][u32:match_id]
 *
 *  ── game client → DB server ──────────────────────────────────────────────
 *
 *  25  LIST_REQUEST
 *        [u8:25]
 *        reply: type 26
 *
 *  30  JOIN_REQUEST
 *        [u8:30][u32:lobby_id][u8:has_password]
 *        if has_password: [lpstr:password_hash]
 *        reply: type 31
 *
 *  ── DB server → game client ──────────────────────────────────────────────
 *
 *  26  LIST_RESPONSE
 *        [u8:26][u8:count]
 *        per lobby: [u32:id][lpstr:name][lpstr:host_ip][u16:port]
 *                   [u8:current_players][u8:max_players]
 *                   [u8:has_password][u8:is_active]
 *
 *  31  JOIN_RESPONSE
 *        [u8:31][u8:result]
 *        result 0 = approved  → [lpstr:host_ip][u16:host_port]
 *        result 1 = wrong password
 *        result 2 = lobby not found
 *
 * ════════════════════════════════════════════════════════════════════════════
 *  BUILD
 * ════════════════════════════════════════════════════════════════════════════
 *
 *  System SQLite:
 *    g++ lobby_db_server.cpp -o lobby_db_server.exe -lws2_32 -lsqlite3
 *
 *  Amalgamation (sqlite3.c + sqlite3.h in same folder):
 *    g++ lobby_db_server.cpp sqlite3.c -o lobby_db_server.exe -lws2_32
 */

#include <winsock2.h>
#include <iostream>
#include <string>
#include <vector>
#include <map>
#include <cstdint>
#include <cstring>
#include <chrono>
#include <sqlite3.h>

#pragma comment(lib, "ws2_32.lib")

// ── Configuration ─────────────────────────────────────────────────────────────
#define DB_PORT          8888
#define DB_FILE          "game_data.db"
#define LOBBY_TIMEOUT_S  15     // seconds without heartbeat before a lobby is pruned

// ── Packet type IDs ───────────────────────────────────────────────────────────
#define PKT_REGISTER         20
#define PKT_REGISTER_ACK     21
#define PKT_UPDATE_PLAYERS   22
#define PKT_DEREGISTER       23
#define PKT_HEARTBEAT        24
#define PKT_LIST_REQUEST     25
#define PKT_LIST_RESPONSE    26
#define PKT_MATCH_START      27
#define PKT_MATCH_START_ACK  28
#define PKT_JOIN_REQUEST     30
#define PKT_JOIN_RESPONSE    31
#define PKT_KILL_EVENT       32
#define PKT_MATCH_END        33

// ── Join result codes ─────────────────────────────────────────────────────────
#define JOIN_OK              0
#define JOIN_WRONG_PASSWORD  1
#define JOIN_NOT_FOUND       2

using Clock     = std::chrono::steady_clock;
using TimePoint = std::chrono::time_point<Clock>;

sqlite3* db = nullptr;
std::map<uint32_t, TimePoint> lobbyHeartbeat;   // lobby_id → last heartbeat time

// ════════════════════════════════════════════════════════════════════════════
//  String packet helpers
// ════════════════════════════════════════════════════════════════════════════

// Read a length-prefixed string from buf at offset. Returns bytes consumed.
int lp_read(const char* buf, int off, int len, std::string& out) {
    if (off >= len) return 0;
    uint8_t slen = (uint8_t)buf[off];
    if (off + 1 + slen > len) return 0;
    out = std::string(buf + off + 1, slen);
    return 1 + slen;
}

// Write a length-prefixed string to buf at offset. Returns bytes written.
int lp_write(char* buf, int off, const std::string& s) {
    uint8_t slen = (uint8_t)(s.size() > 63 ? 63 : s.size());
    buf[off] = (char)slen;
    memcpy(buf + off + 1, s.c_str(), slen);
    return 1 + slen;
}

// ════════════════════════════════════════════════════════════════════════════
//  Database initialisation
// ════════════════════════════════════════════════════════════════════════════

void db_exec(const char* sql) {
    char* err = nullptr;
    if (sqlite3_exec(db, sql, nullptr, nullptr, &err) != SQLITE_OK) {
        std::cerr << "SQL error: " << err << "\n  -> " << sql << "\n";
        sqlite3_free(err);
    }
}

void db_init() {
    if (sqlite3_open(DB_FILE, &db) != SQLITE_OK) {
        std::cerr << "Cannot open database: " << sqlite3_errmsg(db) << "\n";
        exit(1);
    }
    db_exec("PRAGMA foreign_keys = ON;");
    db_exec("PRAGMA journal_mode = WAL;");   // safer for concurrent access

    db_exec(
        "CREATE TABLE IF NOT EXISTS lobbies ("
        "  id              INTEGER PRIMARY KEY AUTOINCREMENT,"
        "  lobby_name      TEXT    NOT NULL,"
        "  host_ip         TEXT    NOT NULL,"
        "  host_port       INTEGER NOT NULL,"
        "  max_players     INTEGER NOT NULL,"
        "  current_players INTEGER NOT NULL DEFAULT 0,"
        "  password_hash   TEXT    DEFAULT NULL,"
        "  is_active       INTEGER NOT NULL DEFAULT 0,"
        "  match_id        INTEGER DEFAULT NULL,"
        "  created_at      DATETIME DEFAULT CURRENT_TIMESTAMP"
        ");"
    );
    db_exec(
        "CREATE TABLE IF NOT EXISTS matches ("
        "  id          INTEGER PRIMARY KEY AUTOINCREMENT,"
        "  lobby_id    INTEGER NOT NULL,"
        "  started_at  DATETIME DEFAULT CURRENT_TIMESTAMP,"
        "  ended_at    DATETIME DEFAULT NULL"
        ");"
    );
    db_exec(
        "CREATE TABLE IF NOT EXISTS players ("
        "  id           INTEGER PRIMARY KEY AUTOINCREMENT,"
        "  pid          INTEGER NOT NULL,"
        "  display_name TEXT    NOT NULL DEFAULT 'Player',"
        "  created_at   DATETIME DEFAULT CURRENT_TIMESTAMP"
        ");"
    );
    db_exec(
        "CREATE TABLE IF NOT EXISTS match_players ("
        "  id         INTEGER PRIMARY KEY AUTOINCREMENT,"
        "  match_id   INTEGER NOT NULL REFERENCES matches(id),"
        "  player_id  INTEGER NOT NULL REFERENCES players(id),"
        "  pid        INTEGER NOT NULL,"
        "  kills      INTEGER NOT NULL DEFAULT 0,"
        "  deaths     INTEGER NOT NULL DEFAULT 0"
        ");"
    );

    std::cout << "Database ready: " << DB_FILE << "\n";

    // Clear all lobbies left over from any previous server run.
    // Any server.exe that was alive would have sent a deregister on clean
    // shutdown, but if it was killed the rows stay.  Since the DB server
    // is the authority, wiping on startup is the safest approach —
    // game servers re-register within seconds of starting.
    char* err = nullptr;
    if (sqlite3_exec(db, "DELETE FROM lobbies;", nullptr, nullptr, &err) != SQLITE_OK) {
        std::cerr << "Startup lobby purge failed: " << err << "\n";
        sqlite3_free(err);
    } else {
        std::cout << "Startup: all stale lobbies cleared.\n";
    }
}

// ════════════════════════════════════════════════════════════════════════════
//  Lobby operations
// ════════════════════════════════════════════════════════════════════════════

uint32_t lobby_register(const std::string& name, const std::string& ip,
                         uint16_t port, uint8_t maxP,
                         const std::string& pwHash) {
    const char* sql =
        "INSERT INTO lobbies (lobby_name,host_ip,host_port,max_players,password_hash)"
        " VALUES (?,?,?,?,?);";
    sqlite3_stmt* st;
    if (sqlite3_prepare_v2(db, sql, -1, &st, nullptr) != SQLITE_OK) return 0;
    sqlite3_bind_text(st, 1, name.c_str(), -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(st, 2, ip.c_str(),   -1, SQLITE_TRANSIENT);
    sqlite3_bind_int (st, 3, port);
    sqlite3_bind_int (st, 4, maxP);
    if (pwHash.empty()) sqlite3_bind_null(st, 5);
    else                sqlite3_bind_text(st, 5, pwHash.c_str(), -1, SQLITE_TRANSIENT);
    sqlite3_step(st);
    sqlite3_finalize(st);
    return (uint32_t)sqlite3_last_insert_rowid(db);
}

void lobby_update_players(uint32_t lobbyId, uint8_t count) {
    sqlite3_stmt* st;
    sqlite3_prepare_v2(db,
        "UPDATE lobbies SET current_players=? WHERE id=?;", -1, &st, nullptr);
    sqlite3_bind_int(st, 1, count);
    sqlite3_bind_int(st, 2, lobbyId);
    sqlite3_step(st);
    sqlite3_finalize(st);
}

void lobby_set_active(uint32_t lobbyId, int active, uint32_t matchId) {
    sqlite3_stmt* st;
    sqlite3_prepare_v2(db,
        "UPDATE lobbies SET is_active=?, match_id=? WHERE id=?;", -1, &st, nullptr);
    sqlite3_bind_int(st, 1, active);
    if (matchId == 0) sqlite3_bind_null(st, 2);
    else              sqlite3_bind_int (st, 2, (int)matchId);
    sqlite3_bind_int(st, 3, lobbyId);
    sqlite3_step(st);
    sqlite3_finalize(st);
}

void lobby_deregister(uint32_t lobbyId) {
    sqlite3_stmt* st;
    sqlite3_prepare_v2(db, "DELETE FROM lobbies WHERE id=?;", -1, &st, nullptr);
    sqlite3_bind_int(st, 1, lobbyId);
    sqlite3_step(st);
    sqlite3_finalize(st);
    lobbyHeartbeat.erase(lobbyId);
    std::cout << "Lobby " << lobbyId << " removed.\n";
}

// ════════════════════════════════════════════════════════════════════════════
//  Match & stats operations
// ════════════════════════════════════════════════════════════════════════════

struct PlayerEntry { uint16_t pid; std::string name; };

uint32_t match_create(uint32_t lobbyId,
                       const std::vector<PlayerEntry>& playerList) {
    // Insert match row
    {
        sqlite3_stmt* st;
        sqlite3_prepare_v2(db,
            "INSERT INTO matches (lobby_id) VALUES (?);", -1, &st, nullptr);
        sqlite3_bind_int(st, 1, lobbyId);
        sqlite3_step(st);
        sqlite3_finalize(st);
    }
    uint32_t matchId = (uint32_t)sqlite3_last_insert_rowid(db);

    for (auto& p : playerList) {
        // Find or create global player record (keyed on pid for now)
        int64_t playerId = 0;
        {
            sqlite3_stmt* st;
            sqlite3_prepare_v2(db,
                "SELECT id FROM players WHERE pid=? LIMIT 1;", -1, &st, nullptr);
            sqlite3_bind_int(st, 1, p.pid);
            if (sqlite3_step(st) == SQLITE_ROW) playerId = sqlite3_column_int64(st, 0);
            sqlite3_finalize(st);
        }
        if (playerId == 0) {
            sqlite3_stmt* st;
            sqlite3_prepare_v2(db,
                "INSERT INTO players (pid, display_name) VALUES (?,?);",
                -1, &st, nullptr);
            sqlite3_bind_int (st, 1, p.pid);
            sqlite3_bind_text(st, 2, p.name.c_str(), -1, SQLITE_TRANSIENT);
            sqlite3_step(st);
            sqlite3_finalize(st);
            playerId = sqlite3_last_insert_rowid(db);
        }

        // Insert match_players row
        sqlite3_stmt* st;
        sqlite3_prepare_v2(db,
            "INSERT INTO match_players (match_id, player_id, pid) VALUES (?,?,?);",
            -1, &st, nullptr);
        sqlite3_bind_int64(st, 1, matchId);
        sqlite3_bind_int64(st, 2, playerId);
        sqlite3_bind_int  (st, 3, p.pid);
        sqlite3_step(st);
        sqlite3_finalize(st);
    }

    lobby_set_active(lobbyId, 1, matchId);
    std::cout << "Match " << matchId << " started — lobby " << lobbyId
              << " (" << playerList.size() << " players)\n";
    return matchId;
}

void match_record_kill(uint32_t matchId, uint16_t killerPid, uint16_t victimPid) {
    auto run = [&](const char* sql, int pid) {
        sqlite3_stmt* st;
        sqlite3_prepare_v2(db, sql, -1, &st, nullptr);
        sqlite3_bind_int(st, 1, matchId);
        sqlite3_bind_int(st, 2, pid);
        sqlite3_step(st);
        sqlite3_finalize(st);
    };
    run("UPDATE match_players SET kills=kills+1  WHERE match_id=? AND pid=?;", killerPid);
    run("UPDATE match_players SET deaths=deaths+1 WHERE match_id=? AND pid=?;", victimPid);
    std::cout << "Kill: match=" << matchId
              << " killer=" << killerPid << " victim=" << victimPid << "\n";
}

void match_end(uint32_t matchId, uint32_t lobbyId) {
    {
        sqlite3_stmt* st;
        sqlite3_prepare_v2(db,
            "UPDATE matches SET ended_at=datetime('now') WHERE id=?;",
            -1, &st, nullptr);
        sqlite3_bind_int(st, 1, matchId);
        sqlite3_step(st);
        sqlite3_finalize(st);
    }

    // Print scoreboard to console
    {
        sqlite3_stmt* st;
        sqlite3_prepare_v2(db,
            "SELECT p.display_name, mp.pid, mp.kills, mp.deaths"
            " FROM match_players mp JOIN players p ON p.id=mp.player_id"
            " WHERE mp.match_id=? ORDER BY mp.kills DESC, mp.deaths ASC;",
            -1, &st, nullptr);
        sqlite3_bind_int(st, 1, matchId);
        std::cout << "── Scoreboard  match " << matchId << " ──────────────\n";
        std::cout << "  Name               pid   K   D\n";
        while (sqlite3_step(st) == SQLITE_ROW) {
            std::cout << "  "
                << sqlite3_column_text(st, 0) << "\t"
                << sqlite3_column_int (st, 1) << "\t"
                << sqlite3_column_int (st, 2) << "\t"
                << sqlite3_column_int (st, 3) << "\n";
        }
        sqlite3_finalize(st);
    }

    lobby_set_active(lobbyId, 0, 0);
    std::cout << "Match " << matchId << " finalised.\n";
}

// ════════════════════════════════════════════════════════════════════════════
//  Lobby list response
// ════════════════════════════════════════════════════════════════════════════

void send_lobby_list(SOCKET sock, const sockaddr_in& dest) {
    sqlite3_stmt* st;
    sqlite3_prepare_v2(db,
        "SELECT id, lobby_name, host_ip, host_port,"
        " current_players, max_players,"
        " CASE WHEN password_hash IS NULL THEN 0 ELSE 1 END,"
        " is_active"
        " FROM lobbies ORDER BY id;",
        -1, &st, nullptr);

    struct Row { uint32_t id; std::string name, ip;
                 uint16_t port; uint8_t cur, max, hasPw, active; };
    std::vector<Row> rows;
    while (sqlite3_step(st) == SQLITE_ROW) {
        Row r;
        r.id     = (uint32_t)sqlite3_column_int (st, 0);
        r.name   = (const char*)sqlite3_column_text(st, 1);
        r.ip     = (const char*)sqlite3_column_text(st, 2);
        r.port   = (uint16_t)sqlite3_column_int (st, 3);
        r.cur    = (uint8_t) sqlite3_column_int (st, 4);
        r.max    = (uint8_t) sqlite3_column_int (st, 5);
        r.hasPw  = (uint8_t) sqlite3_column_int (st, 6);
        r.active = (uint8_t) sqlite3_column_int (st, 7);
        rows.push_back(r);
    }
    sqlite3_finalize(st);
    if (rows.size() > 20) rows.resize(20);

    char buf[1400];
    int off = 0;
    buf[off++] = PKT_LIST_RESPONSE;
    buf[off++] = (uint8_t)rows.size();
    for (auto& r : rows) {
        memcpy(buf + off, &r.id,   4); off += 4;
        off += lp_write(buf, off, r.name);
        off += lp_write(buf, off, r.ip);
        memcpy(buf + off, &r.port, 2); off += 2;
        buf[off++] = r.cur;
        buf[off++] = r.max;
        buf[off++] = r.hasPw;
        buf[off++] = r.active;
    }
    sendto(sock, buf, off, 0, (const sockaddr*)&dest, sizeof(dest));
    std::cout << "Sent lobby list (" << rows.size() << ") to "
              << inet_ntoa(dest.sin_addr) << "\n";
}

// ════════════════════════════════════════════════════════════════════════════
//  Join request handler
// ════════════════════════════════════════════════════════════════════════════

void handle_join(SOCKET sock, const sockaddr_in& src,
                  uint32_t lobbyId, bool hasPw, const std::string& pwHash) {
    char reply[128];
    int off = 0;
    reply[off++] = PKT_JOIN_RESPONSE;

    sqlite3_stmt* st;
    sqlite3_prepare_v2(db,
        "SELECT host_ip, host_port, password_hash FROM lobbies WHERE id=?;",
        -1, &st, nullptr);
    sqlite3_bind_int(st, 1, lobbyId);

    if (sqlite3_step(st) != SQLITE_ROW) {
        sqlite3_finalize(st);
        reply[off++] = JOIN_NOT_FOUND;
        sendto(sock, reply, off, 0, (const sockaddr*)&src, sizeof(src));
        return;
    }

    std::string hostIp   = (const char*)sqlite3_column_text(st, 0);
    uint16_t    hostPort = (uint16_t)sqlite3_column_int(st, 1);
    bool        dbHasPw  = (sqlite3_column_type(st, 2) != SQLITE_NULL);
    std::string dbPwHash = dbHasPw ? (const char*)sqlite3_column_text(st, 2) : "";
    sqlite3_finalize(st);

    if (dbHasPw && (!hasPw || pwHash != dbPwHash)) {
        reply[off++] = JOIN_WRONG_PASSWORD;
        sendto(sock, reply, off, 0, (const sockaddr*)&src, sizeof(src));
        std::cout << "Join denied (wrong pw) lobby " << lobbyId << "\n";
        return;
    }

    reply[off++] = JOIN_OK;
    off += lp_write(reply, off, hostIp);
    memcpy(reply + off, &hostPort, 2); off += 2;
    sendto(sock, reply, off, 0, (const sockaddr*)&src, sizeof(src));
    std::cout << "Join approved: lobby " << lobbyId
              << " → " << hostIp << ":" << hostPort << "\n";
}

// ════════════════════════════════════════════════════════════════════════════
//  Heartbeat pruner
// ════════════════════════════════════════════════════════════════════════════

void prune_stale() {
    auto now = Clock::now();

    // 1. Remove lobbies whose heartbeat has expired
    for (auto it = lobbyHeartbeat.begin(); it != lobbyHeartbeat.end(); ) {
        if (std::chrono::duration_cast<std::chrono::seconds>(
                now - it->second).count() > LOBBY_TIMEOUT_S) {
            uint32_t id = it->first;
            it = lobbyHeartbeat.erase(it);
            std::cout << "Lobby " << id << " timed out.\n";
            lobby_deregister(id);
        } else { ++it; }
    }

    // 2. Remove any DB rows that have no heartbeat entry at all
    // (can happen if the DB server restarted while game servers were running)
    sqlite3_stmt* st;
    if (sqlite3_prepare_v2(db, "SELECT id FROM lobbies;", -1, &st, nullptr) == SQLITE_OK) {
        std::vector<uint32_t> orphans;
        while (sqlite3_step(st) == SQLITE_ROW) {
            uint32_t id = (uint32_t)sqlite3_column_int(st, 0);
            if (lobbyHeartbeat.find(id) == lobbyHeartbeat.end())
                orphans.push_back(id);
        }
        sqlite3_finalize(st);
        for (uint32_t id : orphans) {
            std::cout << "Removing orphan lobby " << id << " (no heartbeat).\n";
            lobby_deregister(id);
        }
    }
}

// ════════════════════════════════════════════════════════════════════════════
//  main
// ════════════════════════════════════════════════════════════════════════════

int main() {
    WSADATA wsa;
    WSAStartup(MAKEWORD(2, 2), &wsa);
    db_init();

    SOCKET sock = socket(AF_INET, SOCK_DGRAM, 0);
    sockaddr_in srvAddr{};
    srvAddr.sin_family      = AF_INET;
    srvAddr.sin_port        = htons(DB_PORT);
    srvAddr.sin_addr.s_addr = INADDR_ANY;
    bind(sock, (sockaddr*)&srvAddr, sizeof(srvAddr));

    DWORD timeout = 1000;
    setsockopt(sock, SOL_SOCKET, SO_RCVTIMEO, (char*)&timeout, sizeof(timeout));
    std::cout << "Lobby DB server on UDP port " << DB_PORT << "\n";

    char buf[1024];
    sockaddr_in src{};
    int srcLen = sizeof(src);

    while (true) {
        prune_stale();

        int bytes = recvfrom(sock, buf, sizeof(buf) - 1, 0,
                             (sockaddr*)&src, &srcLen);
        if (bytes <= 0) continue;

        uint8_t type = (uint8_t)buf[0];
        int     off  = 1;

        // ── 20  REGISTER ─────────────────────────────────────────────────────
        if (type == PKT_REGISTER) {
            std::string name, ip, pwHash;
            off += lp_read(buf, off, bytes, name);
            off += lp_read(buf, off, bytes, ip);
            if (off + 3 > bytes) continue;
            uint16_t port; memcpy(&port, buf + off, 2); off += 2;
            uint8_t maxP  = (uint8_t)buf[off++];
            uint8_t hasPw = (off < bytes) ? (uint8_t)buf[off++] : 0;
            if (hasPw) off += lp_read(buf, off, bytes, pwHash);

            uint32_t lid = lobby_register(name, ip, port, maxP, pwHash);
            lobbyHeartbeat[lid] = Clock::now();

            char ack[5]; ack[0] = PKT_REGISTER_ACK;
            memcpy(ack + 1, &lid, 4);
            sendto(sock, ack, 5, 0, (sockaddr*)&src, srcLen);
            std::cout << "Registered lobby [" << lid << "] \"" << name
                      << "\" " << ip << ":" << port << "\n";
        }

        // ── 22  UPDATE_PLAYERS ────────────────────────────────────────────────
        else if (type == PKT_UPDATE_PLAYERS && bytes >= 6) {
            uint32_t lid; uint8_t count;
            memcpy(&lid, buf + 1, 4); count = (uint8_t)buf[5];
            lobby_update_players(lid, count);
        }

        // ── 23  DEREGISTER ────────────────────────────────────────────────────
        else if (type == PKT_DEREGISTER && bytes >= 5) {
            uint32_t lid; memcpy(&lid, buf + 1, 4);
            lobby_deregister(lid);
        }

        // ── 24  HEARTBEAT ─────────────────────────────────────────────────────
        else if (type == PKT_HEARTBEAT && bytes >= 5) {
            uint32_t lid; memcpy(&lid, buf + 1, 4);
            lobbyHeartbeat[lid] = Clock::now();
        }

        // ── 25  LIST_REQUEST ──────────────────────────────────────────────────
        else if (type == PKT_LIST_REQUEST) {
            send_lobby_list(sock, src);
        }

        // ── 27  MATCH_START ───────────────────────────────────────────────────
        else if (type == PKT_MATCH_START && bytes >= 6) {
            uint32_t lobbyId; memcpy(&lobbyId, buf + 1, 4);
            uint8_t pcount = (uint8_t)buf[5];
            off = 6;
            std::vector<PlayerEntry> players;
            for (int i = 0; i < pcount && off < bytes; i++) {
                PlayerEntry pe;
                memcpy(&pe.pid, buf + off, 2); off += 2;
                int n = lp_read(buf, off, bytes, pe.name);
                if (n == 0) pe.name = "Player";
                else off += n;
                players.push_back(pe);
            }
            uint32_t matchId = match_create(lobbyId, players);
            char ack[5]; ack[0] = PKT_MATCH_START_ACK;
            memcpy(ack + 1, &matchId, 4);
            sendto(sock, ack, 5, 0, (sockaddr*)&src, srcLen);
        }

        // ── 30  JOIN_REQUEST ──────────────────────────────────────────────────
        else if (type == PKT_JOIN_REQUEST && bytes >= 6) {
            uint32_t lobbyId; memcpy(&lobbyId, buf + 1, 4);
            uint8_t hasPw = (uint8_t)buf[5];
            std::string pwHash;
            if (hasPw) lp_read(buf, 6, bytes, pwHash);
            handle_join(sock, src, lobbyId, hasPw != 0, pwHash);
        }

        // ── 32  KILL_EVENT ────────────────────────────────────────────────────
        else if (type == PKT_KILL_EVENT && bytes >= 9) {
            uint32_t matchId; uint16_t killer, victim;
            memcpy(&matchId, buf + 1, 4);
            memcpy(&killer,  buf + 5, 2);
            memcpy(&victim,  buf + 7, 2);
            match_record_kill(matchId, killer, victim);
        }

        // ── 33  MATCH_END ─────────────────────────────────────────────────────
        else if (type == PKT_MATCH_END && bytes >= 9) {
            uint32_t matchId, lobbyId;
            memcpy(&matchId, buf + 1, 4);
            memcpy(&lobbyId, buf + 5, 4);
            match_end(matchId, lobbyId);
        }
    }

    sqlite3_close(db);
    closesocket(sock);
    WSACleanup();
    return 0;
}
