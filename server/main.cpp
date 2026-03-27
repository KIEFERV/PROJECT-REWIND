#include <winsock2.h>
#include <iostream>
#include <map>
#include <string>
#include <cstdint>

#pragma comment(lib, "ws2_32.lib")

std::string addrKey(const sockaddr_in& addr) {
    return std::string(inet_ntoa(addr.sin_addr)) + ":" + std::to_string(ntohs(addr.sin_port));
}

struct Player {
    std::string key;
    sockaddr_in addr;
    uint16_t pid;  // numeric player ID we assign
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

    std::cout << "UDP server ready.\n";

    std::map<std::string, Player> players;
    uint16_t nextPid = 1;

    char buffer[512];
    sockaddr_in clientAddr;
    int clientLen = sizeof(clientAddr);

    while (true) {
        int bytes = recvfrom(sock, buffer, sizeof(buffer) - 1, 0,
                             (sockaddr*)&clientAddr, &clientLen);
        if (bytes <= 0) continue;

        std::string key = addrKey(clientAddr);

        // Register new player, send them their assigned ID
        if (players.find(key) == players.end()) {
            players[key] = { key, clientAddr, nextPid++ };
            uint16_t assignedId = players[key].pid;
            std::cout << "New player: " << key << " assigned ID " << assignedId << "\n";

            // Send back: type=2 (joined), their ID as 2 bytes
            char joinAck[3];
            joinAck[0] = 2;  // type 2 = "here is your ID"
            memcpy(joinAck + 1, &assignedId, 2);
            sendto(sock, joinAck, 3, 0, (sockaddr*)&clientAddr, clientLen);
        }

        uint8_t type = (uint8_t)buffer[0];

        if (type == 1) {
            // Player state update — prepend their ID and broadcast
            uint16_t senderPid = players[key].pid;

            // Build broadcast: [type=1][pid 2 bytes][rest of packet]
            char broadcast[512];
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
    }

    closesocket(sock);
    WSACleanup();
    return 0;
}