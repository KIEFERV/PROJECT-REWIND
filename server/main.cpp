/*
 * main.cpp  —  Game server  v3
 *
 * Reads its configuration entirely from command-line arguments so that the
 * GameMaker client can launch it directly without editing source or config files.
 *
 * ─── USAGE ──────────────────────────────────────────────────────────────────
 *
 *   server.exe <lobby_name> <db_ip> <public_ip> [password_hash]
 *
 *   lobby_name     Human-readable name shown in the lobby browser (quoted if spaces)
 *   db_ip          IP address of the lobby_db_server machine
 *   public_ip      This machine's LAN/public IP that clients will connect to
 *   password_hash  (optional) djb2 hex hash of the lobby password.
 *                  Omit or pass "" for a public lobby.
 *
 *   Example (public):
 *     server.exe "Dave's Game" 192.168.1.10 192.168.1.20
 *
 *   Example (private):
 *     server.exe "Secret Room" 192.168.1.10 192.168.1.20 a3f1c9b2
 *
 * ─── FIXED CONSTANTS ─────────────────────────────────────────────────────────
 *   DB_PORT      8888   (must match lobby_db_server)
 *   GAME_PORT    7777   (clients connect here)
 *   MAX_PLAYERS  4
 *
 * ─── PACKET PROTOCOL (unchanged from v2) ─────────────────────────────────────
 *   Game:  1 player-state  2 id-assign  3 player-left  4 bullet
 *          5 timer  6 match-end  7 match-start  8 not-enough
 *          9 disconnect  10 join-request  11 kill-report
 *   DB:    20 register  21 reg-ack  22 update-players  23 deregister
 *          24 heartbeat  27 match-start  28 match-start-ack
 *          32 kill-event  33 match-end
 *
 * ─── BUILD ───────────────────────────────────────────────────────────────────
 *   g++ main.cpp -o server.exe -lws2_32
 */

#include <winsock2.h>
#include <iostream>
#include <map>
#include <string>
#include <cstdint>
#include <cstring>
#include <chrono>

#pragma comment(lib, "ws2_32.lib")

// ── Fixed configuration ────────────────────────────────────────────────────────
static const uint16_t DB_PORT    = 8888;
static const uint16_t GAME_PORT  = 7777;
static const uint8_t  MAX_PLAYERS = 4;

// ── Game packet types ─────────────────────────────────────────────────────────
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
#define PKT_KEEPALIVE     12  // lobby keepalive — refreshes lastSeen, no other effect

// ── DB packet types ───────────────────────────────────────────────────────────
#define DB_REGISTER         20
#define DB_REGISTER_ACK     21
#define DB_UPDATE_PLAYERS   22
#define DB_DEREGISTER       23
#define DB_HEARTBEAT        24
#define DB_MATCH_START      27
#define DB_MATCH_START_ACK  28
#define DB_KILL_EVENT       32
#define DB_MATCH_END        33

using Clock     = std::chrono::steady_clock;
using TimePoint = std::chrono::time_point<Clock>;

std::string addrKey(const sockaddr_in& a) {
    return std::string(inet_ntoa(a.sin_addr)) + ":" +
           std::to_string(ntohs(a.sin_port));
}

struct Player { std::string key; sockaddr_in addr; uint16_t pid; TimePoint lastSeen; };

// ── String packet helper ──────────────────────────────────────────────────────
int lp_write(char* buf, int off, const std::string& s) {
    uint8_t len = (uint8_t)(s.size() > 63 ? 63 : s.size());
    buf[off] = (char)len;
    memcpy(buf + off + 1, s.c_str(), len);
    return 1 + len;
}

// ── DB connection state ───────────────────────────────────────────────────────
SOCKET      dbSock          = INVALID_SOCKET;
sockaddr_in dbAddr{};
uint32_t    myLobbyId       = 0;
uint32_t    myMatchId       = 0;
bool        lobbyReg        = false;
bool        matchAckPending = false;
TimePoint   lastHB, lastPCUpdate;

// ── DB helpers ────────────────────────────────────────────────────────────────
void db_register(const std::string& name, const std::string& ip,
                  uint16_t port, uint8_t maxP, const std::string& pwHash) {
    char buf[256]; int off = 0;
    buf[off++] = DB_REGISTER;
    off += lp_write(buf, off, name);
    off += lp_write(buf, off, ip);
    memcpy(buf + off, &port, 2); off += 2;
    buf[off++] = maxP;
    if (pwHash.empty()) {
        buf[off++] = 0;
    } else {
        buf[off++] = 1;
        off += lp_write(buf, off, pwHash);
    }
    sendto(dbSock, buf, off, 0, (sockaddr*)&dbAddr, sizeof(dbAddr));
    std::cout << "Sent REGISTER: \"" << name << "\" pw=" << (pwHash.empty() ? "none" : "set") << "\n";
}

void db_heartbeat() {
    if (!lobbyReg) return;
    char buf[5]; buf[0] = DB_HEARTBEAT;
    memcpy(buf + 1, &myLobbyId, 4);
    sendto(dbSock, buf, 5, 0, (sockaddr*)&dbAddr, sizeof(dbAddr));
}

void db_update_players(uint8_t count) {
    if (!lobbyReg) return;
    char buf[6]; buf[0] = DB_UPDATE_PLAYERS;
    memcpy(buf + 1, &myLobbyId, 4); buf[5] = count;
    sendto(dbSock, buf, 6, 0, (sockaddr*)&dbAddr, sizeof(dbAddr));
}

void db_deregister() {
    if (!lobbyReg) return;
    char buf[5]; buf[0] = DB_DEREGISTER;
    memcpy(buf + 1, &myLobbyId, 4);
    sendto(dbSock, buf, 5, 0, (sockaddr*)&dbAddr, sizeof(dbAddr));
    std::cout << "Sent DEREGISTER.\n";
}

void db_match_start(const std::map<std::string, Player>& players) {
    if (!lobbyReg) return;
    char buf[512]; int off = 0;
    buf[off++] = DB_MATCH_START;
    memcpy(buf + off, &myLobbyId, 4); off += 4;
    buf[off++] = (uint8_t)players.size();
    for (auto& pair : players) {
        memcpy(buf + off, &pair.second.pid, 2); off += 2;
        std::string dname = "Player" + std::to_string(pair.second.pid);
        off += lp_write(buf, off, dname);
    }
    sendto(dbSock, buf, off, 0, (sockaddr*)&dbAddr, sizeof(dbAddr));
    matchAckPending = true;
    std::cout << "Sent MATCH_START.\n";
}

void db_kill(uint16_t killerPid, uint16_t victimPid) {
    if (myMatchId == 0) return;
    char buf[9]; buf[0] = DB_KILL_EVENT;
    memcpy(buf + 1, &myMatchId, 4);
    memcpy(buf + 5, &killerPid, 2);
    memcpy(buf + 7, &victimPid, 2);
    sendto(dbSock, buf, 9, 0, (sockaddr*)&dbAddr, sizeof(dbAddr));
}

void db_match_end() {
    if (myMatchId == 0 || !lobbyReg) return;
    char buf[9]; buf[0] = DB_MATCH_END;
    memcpy(buf + 1, &myMatchId, 4);
    memcpy(buf + 5, &myLobbyId, 4);
    sendto(dbSock, buf, 9, 0, (sockaddr*)&dbAddr, sizeof(dbAddr));
    std::cout << "Sent MATCH_END.\n";
    myMatchId = 0;
}

void db_poll() {
    char buf[16];
    sockaddr_in from{}; int fromLen = sizeof(from);
    int bytes = recvfrom(dbSock, buf, sizeof(buf), 0, (sockaddr*)&from, &fromLen);
    if (bytes <= 0) return;
    uint8_t type = (uint8_t)buf[0];
    if (type == DB_REGISTER_ACK && bytes >= 5 && !lobbyReg) {
        memcpy(&myLobbyId, buf + 1, 4);
        lobbyReg = true;
        lastHB = lastPCUpdate = Clock::now();
        std::cout << "Lobby registered. ID=" << myLobbyId << "\n";
    } else if (type == DB_MATCH_START_ACK && bytes >= 5 && matchAckPending) {
        memcpy(&myMatchId, buf + 1, 4);
        matchAckPending = false;
        std::cout << "Match ID=" << myMatchId << "\n";
    }
}

// ════════════════════════════════════════════════════════════════════════════
//  main
// ════════════════════════════════════════════════════════════════════════════

int main(int argc, char* argv[]) {
    // Force UTF-8 output so special characters display correctly in cmd.exe
    SetConsoleOutputCP(65001);

    // Print all received args so problems are immediately visible in the console
    std::cout << "server.exe  argc=" << argc << "\n";
    for (int i = 1; i < argc; i++)
        std::cout << "  argv[" << i << "] = \"" << argv[i] << "\"\n";
    std::cout << std::flush;

    if (argc < 4) {
        std::cerr
            << "\nERROR: wrong number of arguments (got " << argc - 1 << ", need 3-4).\n\n"
            << "Usage:\n"
            << "  server.exe <lobby_name> <db_ip> <public_ip> [password_hash]\n\n"
            << "Examples:\n"
            << "  server.exe \"My Lobby\" 127.0.0.1 127.0.0.1\n"
            << "  server.exe \"Secret Room\" 192.168.1.10 192.168.1.20 a3f1c9b2\n\n"
            << "This program is launched automatically by the game client.\n"
            << "Do not double-click it directly unless testing from a command prompt.\n";
        system("pause");
        return 1;
    }

    std::string lobbyName = argv[1];
    std::string dbIp      = argv[2];
    std::string publicIp  = argv[3];
    std::string pwHash    = (argc >= 5) ? argv[4] : "";

    WSADATA wsa;
    if (WSAStartup(MAKEWORD(2, 2), &wsa) != 0) {
        std::cerr << "ERROR: WSAStartup failed.\n";
        system("pause");
        return 1;
    }

    // ── Game socket ───────────────────────────────────────────────────────────
    SOCKET gameSock = socket(AF_INET, SOCK_DGRAM, 0);
    if (gameSock == INVALID_SOCKET) {
        std::cerr << "ERROR: could not create game socket (WSA " << WSAGetLastError() << ").\n";
        system("pause");
        return 1;
    }

    sockaddr_in gameAddr{};
    gameAddr.sin_family      = AF_INET;
    gameAddr.sin_port        = htons(GAME_PORT);
    gameAddr.sin_addr.s_addr = INADDR_ANY;

    if (bind(gameSock, (sockaddr*)&gameAddr, sizeof(gameAddr)) == SOCKET_ERROR) {
        std::cerr << "ERROR: bind failed on port " << GAME_PORT
                  << " (WSA " << WSAGetLastError() << ").\n"
                  << "Most likely cause: another instance of server.exe is already running.\n"
                  << "Close the other instance and try again.\n";
        system("pause");
        return 1;
    }

    // 1 ms timeout — effectively non-blocking. The loop drains ALL pending
    // packets each tick before doing maintenance work.
    DWORD gto = 1;
    setsockopt(gameSock, SOL_SOCKET, SO_RCVTIMEO, (char*)&gto, sizeof(gto));

    // ── DB socket ────────────────────────────────────────────────────────────
    dbSock = socket(AF_INET, SOCK_DGRAM, 0);
    if (dbSock == INVALID_SOCKET) {
        std::cerr << "ERROR: could not create DB socket (WSA " << WSAGetLastError() << ").\n";
        system("pause");
        return 1;
    }

    dbAddr.sin_family      = AF_INET;
    dbAddr.sin_port        = htons(DB_PORT);
    dbAddr.sin_addr.s_addr = inet_addr(dbIp.c_str());
    DWORD dto = 200;
    setsockopt(dbSock, SOL_SOCKET, SO_RCVTIMEO, (char*)&dto, sizeof(dto));

    db_register(lobbyName, publicIp, GAME_PORT, MAX_PLAYERS, pwHash);

    std::cout << "\n=== Game Server Ready ===\n"
              << "  Lobby     : " << lobbyName << "\n"
              << "  Game port : " << GAME_PORT << "\n"
              << "  Public IP : " << publicIp  << "\n"
              << "  DB server : " << dbIp << ":" << DB_PORT << "\n"
              << "  Password  : " << (pwHash.empty() ? "none (public)" : "set (private)") << "\n"
              << "  Max players: " << (int)MAX_PLAYERS << "\n"
              << "========================\n" << std::flush;

    std::map<std::string, Player> players;
    uint16_t nextPid = 1;

    int  matchDuration      = 180;
    int  timeRemaining      = matchDuration;
    bool matchRunning       = false;
    TimePoint lastTimerBroadcast = Clock::now();

    char buffer[512];
    sockaddr_in clientAddr{};
    int clientLen = sizeof(clientAddr);

    while (true) {
        auto now = Clock::now();

        // ── DB maintenance ────────────────────────────────────────────────────
        db_poll();
        if (lobbyReg) {
            if (std::chrono::duration_cast<std::chrono::seconds>(now - lastHB).count() >= 5) {
                db_heartbeat(); lastHB = now;
            }
            if (std::chrono::duration_cast<std::chrono::seconds>(now - lastPCUpdate).count() >= 3) {
                db_update_players((uint8_t)players.size()); lastPCUpdate = now;
            }
        }

        // ── Reject connections if lobby is full ───────────────────────────────
        // (checked at join time below; MAX_PLAYERS enforced there)

        // ── Timeout stale clients ─────────────────────────────────────────────
        for (auto it = players.begin(); it != players.end(); ) {
            auto age = std::chrono::duration_cast<std::chrono::seconds>(
                           now - it->second.lastSeen).count();
            if (age > 5) {
                std::cout << "Timeout: " << it->first << "\n";
                char lm[3]; lm[0] = PKT_PLAYER_LEFT;
                memcpy(lm + 1, &it->second.pid, 2);
                for (auto& p : players) {
                    if (p.first == it->first) continue;
                    sendto(gameSock, lm, 3, 0,
                           (sockaddr*)&p.second.addr, sizeof(p.second.addr));
                }
                it = players.erase(it);
                db_update_players((uint8_t)players.size());
            } else ++it;
        }
        // Reset pid counter when lobby is completely empty so the next
        // host always gets pid=1
        if (players.empty() && nextPid != 1) {
            nextPid = 1;
            matchRunning = false;
            std::cout << "Lobby empty — pid counter reset to 1.\n";
        }

        // ── Match timer ───────────────────────────────────────────────────────
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
                    for (auto& p : players)
                        sendto(gameSock, ep, 1, 0,
                               (sockaddr*)&p.second.addr, sizeof(p.second.addr));
                    db_match_end();
                }
                char tp[3]; tp[0] = PKT_TIMER;
                uint16_t t = (uint16_t)timeRemaining;
                memcpy(tp + 1, &t, 2);
                for (auto& p : players)
                    sendto(gameSock, tp, 3, 0,
                           (sockaddr*)&p.second.addr, sizeof(p.second.addr));
                std::cout << "Time: " << timeRemaining << "\n";
            }
        }

        // ── Drain all pending packets ─────────────────────────────────────────
        // Loop until recvfrom returns nothing. This ensures every packet sent
        // by clients this tick is processed immediately rather than waiting for
        // the next loop iteration.
        while (true) {
        int bytes = recvfrom(gameSock, buffer, sizeof(buffer) - 1, 0,
                             (sockaddr*)&clientAddr, &clientLen);
        if (bytes <= 0) break;

        std::string key  = addrKey(clientAddr);
        uint8_t     type = (uint8_t)buffer[0];

        // ── 255  Ping — echo back without registering a player slot ──────────
        // Used by the GML lobby browser to confirm server.exe is alive.
        if (type == 255) {
            char pong[1] = { (char)255 };
            sendto(gameSock, pong, 1, 0, (sockaddr*)&clientAddr, clientLen);
            continue;  // do NOT fall through to player registration below
        }

        // ── 12  Keepalive — skip registration, just refresh lastSeen ─────────
        // Only meaningful if the player is already registered. If not, ignore.
        if (type == PKT_KEEPALIVE) {
            if (players.count(key))
                players[key].lastSeen = Clock::now();
            continue;
        }

        // ── 9  Graceful disconnect ────────────────────────────────────────────
        if (type == PKT_DISCONNECT) {
            if (players.count(key)) {
                std::cout << "Disconnect: " << key << "\n";
                char lm[3]; lm[0] = PKT_PLAYER_LEFT;
                memcpy(lm + 1, &players[key].pid, 2);
                for (auto& p : players) {
                    if (p.first == key) continue;
                    sendto(gameSock, lm, 3, 0,
                           (sockaddr*)&p.second.addr, sizeof(p.second.addr));
                }
                players.erase(key);
                db_update_players((uint8_t)players.size());
                if (players.empty()) {
                    nextPid = 1;
                    matchRunning = false;
                    std::cout << "Lobby empty — pid counter reset to 1.\n";
                }
            }
            continue;
        }

        // ── Register new player (with MAX_PLAYERS cap) ────────────────────────
        if (!players.count(key)) {
            if ((int)players.size() >= MAX_PLAYERS) {
                std::cout << "Lobby full, rejecting: " << key << "\n";
                continue;
            }
            players[key] = { key, clientAddr, nextPid++, Clock::now() };
            uint16_t pid = players[key].pid;
            if (pid == 1)
                std::cout << "HOST registered: key=" << key << " pid=1\n";
            else
                std::cout << "New player registered: key=" << key << " pid=" << pid << "\n";
            std::cout << "Total players now: " << players.size() << "\n";
            char ja[3]; ja[0] = PKT_ID_ASSIGN;
            memcpy(ja + 1, &pid, 2);
            sendto(gameSock, ja, 3, 0, (sockaddr*)&clientAddr, clientLen);
            db_update_players((uint8_t)players.size());
        }
        players[key].lastSeen = Clock::now();

        // ── 1  Player state broadcast ─────────────────────────────────────────
        if (type == PKT_PLAYER_STATE) {
            uint16_t spid = players[key].pid;
            char bc[512]; bc[0] = PKT_PLAYER_STATE;
            memcpy(bc + 1, &spid, 2);
            memcpy(bc + 3, buffer + 1, bytes - 1);
            int bsz = bytes + 2;
            for (auto& p : players) {
                if (p.first == key) continue;
                sendto(gameSock, bc, bsz, 0,
                       (sockaddr*)&p.second.addr, sizeof(p.second.addr));
            }
        }

        // ── 4  Bullet ─────────────────────────────────────────────────────────
        if (type == PKT_BULLET) {
            uint16_t spid = players[key].pid;
            char bc[512]; bc[0] = PKT_BULLET;
            memcpy(bc + 1, &spid, 2);
            memcpy(bc + 3, buffer + 1, bytes - 1);
            int bsz = bytes + 2;
            for (auto& p : players) {
                if (p.first == key) continue;
                sendto(gameSock, bc, bsz, 0,
                       (sockaddr*)&p.second.addr, sizeof(p.second.addr));
            }
        }

        // ── 7  Match start request ────────────────────────────────────────────
        if (type == PKT_MATCH_START) {
            uint16_t requesterPid = players[key].pid;
            std::cout << "Match start requested by key=" << key
                      << " pid=" << requesterPid << "\n";
            std::cout << "Current players (" << players.size() << "):\n";
            for (auto& p : players)
                std::cout << "  key=" << p.first << " pid=" << p.second.pid << "\n";

            if (requesterPid != 1) {
                std::cout << "Non-host start ignored (pid=" << requesterPid
                          << ", only pid=1 can start).\n";
                continue;
            }
            // Minimum 2 players required to start
            if (players.size() < 2) {
                std::cout << "Not enough players.\n";
                char ne[1] = { PKT_NOT_ENOUGH };
                sendto(gameSock, ne, 1, 0, (sockaddr*)&clientAddr, clientLen);
                continue;
            }
            matchRunning       = true;
            timeRemaining      = matchDuration;
            lastTimerBroadcast = Clock::now();
            std::cout << "Match started!\n";
            char sp[1] = { PKT_MATCH_START };
            for (auto& p : players)
                sendto(gameSock, sp, 1, 0,
                       (sockaddr*)&p.second.addr, sizeof(p.second.addr));
            db_match_start(players);
        }

        // ── 10  Explicit join request ─────────────────────────────────────────
        if (type == PKT_JOIN_REQUEST && players.count(key)) {
            uint16_t pid = players[key].pid;
            char ja[3]; ja[0] = PKT_ID_ASSIGN;
            memcpy(ja + 1, &pid, 2);
            sendto(gameSock, ja, 3, 0, (sockaddr*)&clientAddr, clientLen);
        }

        // ── 11  Kill report ───────────────────────────────────────────────────
        if (type == PKT_KILL_REPORT && bytes >= 5 && matchRunning) {
            uint16_t killerPid, victimPid;
            memcpy(&killerPid, buffer + 1, 2);
            memcpy(&victimPid, buffer + 3, 2);
            if (killerPid == players[key].pid) {
                std::cout << "Kill: " << killerPid << " -> " << victimPid << "\n";
                db_kill(killerPid, victimPid);
            }
        }

        } // end inner packet drain loop
    }   // end outer maintenance loop

    db_deregister();
    closesocket(gameSock);
    closesocket(dbSock);
    WSACleanup();
    return 0;
}
