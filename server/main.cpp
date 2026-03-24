#include <winsock2.h>
#pragma comment(lib, "ws2_32.lib")
#include <iostream>
#include <map>
#include <string>

// Helper: turn an IP+port into a string key like "192.168.1.5:4400"
std::string addrKey(const sockaddr_in& addr) {
    return std::string(inet_ntoa(addr.sin_addr)) + ":" + std::to_string(ntohs(addr.sin_port));
}

struct Player {
    std::string id;
    float x, y;
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

    // Map of "IP:port" → Player
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

        // New player? Register them
        if (players.find(key) == players.end()) {
            players[key] = { key, 0, 0 };
            std::cout << "New player: " << key << "\n";
        }

        // Update their position (expecting "x,y" format from GameMaker)
        float x, y;
        if (sscanf(buffer, "%f,%f", &x, &y) == 2) {
            players[key].x = x;
            players[key].y = y;
        }

        // Send back a simple ack
        sendto(sock, "ok", 2, 0, (sockaddr*)&clientAddr, clientLen);
    }

    closesocket(sock);
    WSACleanup();
    return 0;
}