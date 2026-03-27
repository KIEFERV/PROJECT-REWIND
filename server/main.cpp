#include <winsock2.h>
#include <iostream>
#include <map>
#include <string>

#pragma comment(lib, "ws2_32.lib")

std::string addrKey(const sockaddr_in& addr) {
    return std::string(inet_ntoa(addr.sin_addr)) + ":" + std::to_string(ntohs(addr.sin_port));
}

struct Player {
    std::string id;
    float x, y;
    sockaddr_in addr;  // store the full address so we can send back to them
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
    char buffer[512];
    sockaddr_in clientAddr;
    int clientLen = sizeof(clientAddr);

    while (true) {
        int bytes = recvfrom(sock, buffer, sizeof(buffer) - 1, 0,
                             (sockaddr*)&clientAddr, &clientLen);
        if (bytes <= 0) continue;
        buffer[bytes] = '\0';

        std::string key = addrKey(clientAddr);

        // Register new player
        if (players.find(key) == players.end()) {
            players[key] = { key, 0, 0, clientAddr };
            std::cout << "New player: " << key << "\n";
        }

        // Update their position
        float x, y;
        if (sscanf(buffer, "%f,%f", &x, &y) == 2) {
            players[key].x = x;
            players[key].y = y;
            players[key].addr = clientAddr;

            // Build a broadcast packet: "id:x,y"
            // e.g. "127.0.0.1:55772:100.00,200.00"
            char broadcast[512];
            snprintf(broadcast, sizeof(broadcast), "%s:%f,%f", key.c_str(), x, y);

            // After updating position, add this BEFORE the broadcast loop:
            const char* ack = "ack";
            sendto(sock, ack, strlen(ack), 0, (sockaddr*)&clientAddr, clientLen);

            // Send to every OTHER player
            for (auto& pair : players) {
                if (pair.first == key) continue;  // skip the sender

                std::cout << "Broadcasting to " << pair.first << ": " << broadcast << "\n";
                
                sendto(sock, broadcast, strlen(broadcast), 0,
                       (sockaddr*)&pair.second.addr, sizeof(pair.second.addr));
            }
        }
    }

    closesocket(sock);
    WSACleanup();
    return 0;
}