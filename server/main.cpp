#include <winsock2.h>
#include <iostream>
#include <map>
#include <string>
#include <cstdint>
#include <chrono>

#pragma comment(lib, "ws2_32.lib")

using Clock = std::chrono::steady_clock;
using TimePoint = std::chrono::time_point<Clock>;

std::string addrKey(const sockaddr_in& addr) {
    return std::string(inet_ntoa(addr.sin_addr)) + ":" + std::to_string(ntohs(addr.sin_port));
}

struct Player {
    std::string key;
    sockaddr_in addr;
    uint16_t pid; // assign a player ID
    TimePoint lastSeen;  // track when we last heard from them
};

int main() {
    WSADATA wsa;
    WSAStartup(MAKEWORD(2,2), &wsa);

    SOCKET sock = socket(AF_INET, SOCK_DGRAM, 0);

    sockaddr_in serverAddr;
    serverAddr.sin_family = AF_INET;
    serverAddr.sin_port = htons(7777);
    serverAddr.sin_addr.s_addr = INADDR_ANY;
    bind(sock, (sockaddr*)&serverAddr, sizeof(serverAddr));

    // Set socket timeout so recvfrom doesn't block forever
    // checks for timeouts even when no packets arrive
    DWORD timeout = 1000;  // 1 second
    setsockopt(sock, SOL_SOCKET, SO_RCVTIMEO, (char*)&timeout, sizeof(timeout));

    std::cout << "UDP server ready.\n";

    std::map<std::string, Player> players;
    uint16_t nextPid = 1;

    char buffer[512];
    sockaddr_in clientAddr;
    int clientLen = sizeof(clientAddr);

    int matchDuration = 180; // 3 minutes (seconds)
    int timeRemaining = matchDuration;
    TimePoint lastTimerBroadcast = Clock::now();

    bool matchStarted = false;
    bool matchRunning = false;

    while (true) {
        // Check for timeouts every loop — remove players silent for 5+ seconds
        auto now = Clock::now();
        for (auto it = players.begin(); it != players.end(); ) {
            auto elapsed = std::chrono::duration_cast<std::chrono::seconds>(now - it->second.lastSeen).count();
            if (elapsed > 5) {
                std::cout << "Player timed out: " << it->first << "\n";

                // Tell everyone else this player left
                char leaveMsg[3];
                leaveMsg[0] = 3;  // type 3 = player left
                memcpy(leaveMsg + 1, &it->second.pid, 2);
                for (auto& pair : players) {
                    if (pair.first == it->first) continue;
                    sendto(sock, leaveMsg, 3, 0,
                           (sockaddr*)&pair.second.addr, sizeof(pair.second.addr));
                }

                it = players.erase(it);
            } else {
                ++it;
            }
        }

        if (matchRunning){
            auto now = Clock::now();
            auto elapsed = std::chrono::duration_cast<std::chrono::seconds>(now - lastTimerBroadcast).count();

            if (elapsed >= 1){
                lastTimerBroadcast = Clock::now();
                timeRemaining--;
            
                if (timeRemaining <= 0){
                    timeRemaining = 0; //Reset in case it falls below 0
                    matchRunning = false;
                    std::cout << "Match Over!\n";

                    // Tell all clients match is over
                    char endPacket[1];
                    endPacket[0] = 6;
                    for (auto& pair : players){
                        sendto(sock, endPacket, 1, 0, (sockaddr*)&pair.second.addr, sizeof(pair.second.addr));
                    }
                }
                
                // Build timer packet: [type 5][time remaining as u16]
                char timerPacket[3];
                timerPacket[0] = 5; //set the packet type
                uint16_t t = (uint16_t)timeRemaining;
                memcpy(timerPacket + 1, &t, 2);

                //Send to all players
                for (auto& pair : players){
                    sendto (sock, timerPacket, 3, 0, (sockaddr*)&pair.second.addr, sizeof(pair.second.addr));
                }

                std::cout << "Time remaining: " << timeRemaining << "\n";
            }
        }

        


        int bytes = recvfrom(sock, buffer, sizeof(buffer) - 1, 0,
                             (sockaddr*)&clientAddr, &clientLen);
        if (bytes <= 0) continue;

        std::string key = addrKey(clientAddr);
        uint8_t type = (uint8_t)buffer[0];

        // Type 9 = graceful disconnect
        if (type == 9) {
            if (players.find(key) != players.end()) {
                std::cout << "Player disconnected: " << key << "\n";

                // Tell everyone else
                char leaveMsg[3];
                leaveMsg[0] = 3;
                memcpy(leaveMsg + 1, &players[key].pid, 2);
                for (auto& pair : players) {
                    if (pair.first == key) continue;
                    sendto(sock, leaveMsg, 3, 0,
                           (sockaddr*)&pair.second.addr, sizeof(pair.second.addr));
                }

                players.erase(key);
            }
            continue;
        }

        // Register new player
        if (players.find(key) == players.end()) {
            players[key] = { key, clientAddr, nextPid++, Clock::now() };
            uint16_t assignedId = players[key].pid;
            std::cout << "New player: " << key << " assigned ID " << assignedId << "\n";

            char joinAck[3];
            joinAck[0] = 2; // type 2 - ID
            memcpy(joinAck + 1, &assignedId, 2);
            sendto(sock, joinAck, 3, 0, (sockaddr*)&clientAddr, clientLen);
        }

        // update last seen time
        players[key].lastSeen = Clock::now();

        if (type == 1) { // player
            uint16_t senderPid = players[key].pid;

            char broadcast[512]; // Build broadcast: [type=1][pid 2 bytes][rest of packet]
            broadcast[0] = 1;
            memcpy(broadcast + 1, &senderPid, 2);
            memcpy(broadcast + 3, buffer + 1, bytes - 1);
            int broadcastSize = bytes + 2;

            for (auto& pair : players) {
                if (pair.first == key) continue;
                sendto(sock, broadcast, broadcastSize, 0,
                       (sockaddr*)&pair.second.addr, sizeof(pair.second.addr));
            }
        }

        if (type == 4){ // bullets
            uint16_t senderPid = players[key].pid;

            // DEBUG -  Print raw bytes received
            /*
            std::cout << "Bullet received " << bytes << " bytes: ";
            for (int i = 0; i < bytes; i++) {
            std::cout << (int)(unsigned char)buffer[i] << " ";
            }
            std::cout << "\n";
            */

            char broadcast[512];
            broadcast[0] = 4;
            memcpy(broadcast + 1, &senderPid, 2);
            memcpy(broadcast + 3, buffer + 1, bytes - 1);
            int broadcastSize = bytes + 2;

            std::cout << "Player " << senderPid << " fired a bullet\n";

            // DEBUG - Print raw bytes being broadcast
            /*
            std::cout << "Bullet broadcast " << broadcastSize << " bytes: ";
            for (int i = 0; i < broadcastSize; i++) {
            std::cout << (int)(unsigned char)broadcast[i] << " ";
            }
            std::cout << "\n";
            */

            for(auto& pair : players){
                if (pair.first == key) continue;
                sendto(sock, broadcast, broadcastSize, 0, 
                    (sockaddr*)&pair.second.addr, sizeof(pair.second.addr));
            }
        }

        if (type == 7) {
            uint16_t requesterPid = players[key].pid;

            // Only pid 1 (first player) can start
            if (requesterPid != 1) {
                std::cout << "Non-host tried to start match, ignoring.\n";
            continue;
            }

            // Need at least 2 players
            if (players.size() < 1) { //1 FOR DEDBUG CHANGE BACK TO 2 LATER
                std::cout << "Not enough players to start.\n";

                // Tell the host there aren't enough players
                char notEnough[1];
                notEnough[0] = 8;  // type 8 = not enough players
                sendto(sock, notEnough, 1, 0, (sockaddr*)&clientAddr, clientLen);
                continue;
            }

            // Start the match
            matchStarted = true;
            matchRunning = true;
            timeRemaining = matchDuration;
            lastTimerBroadcast = Clock::now();
            std::cout << "Match started by host!\n";

            // Tell all clients to start
            char startPacket[1];
            startPacket[0] = 7;  // type 7 broadcast = match is starting
            for (auto& pair : players) {
                sendto(sock, startPacket, 1, 0,
               (sockaddr*)&pair.second.addr, sizeof(pair.second.addr));
            }
        }

        if (type == 10) {
            // Join request — player is already registered above, just send them their pid
            if (players.find(key) != players.end()) {
                uint16_t assignedId = players[key].pid;
                char joinAck[3];
                joinAck[0] = 2;
                memcpy(joinAck + 1, &assignedId, 2);
                sendto(sock, joinAck, 3, 0, (sockaddr*)&clientAddr, clientLen);
                std::cout << "Sent pid " << assignedId << " to " << key << "\n";
            }
        }
    }

    closesocket(sock);
    WSACleanup();
    return 0;
}