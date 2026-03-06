#include <iostream>
#include <WS2tcpip.h>
#include <winsock2.h>
#include <string>


#pragma comment (lib, "ws2_32.lib")



using namespace std;

void main()
{
	//start up winsock
	WSADATA data;

	WORD version = MAKEWORD(2, 2);


	int wsOk = WSAStartup(version, &data);
	if (wsOk != 0)
	{

		cout << "Can't start Winsock! " << wsOk;
		return;
	}



	// Create a socket
	SOCKET in = socket(AF_INET, SOCK_DGRAM, 0);

	// Create a server hint structure for the server
	sockaddr_in serverHint;
	serverHint.sin_addr.S_un.S_addr = ADDR_ANY; // Us any IP address 
	serverHint.sin_family = AF_INET; 
	serverHint.sin_port = htons(54000); // Convert from little to big endian

	// bind the socket to the IP and port
	if (bind(in, (sockaddr*)&serverHint, sizeof(serverHint)) == SOCKET_ERROR)
	{
		cout << "Can't bind socket! " << WSAGetLastError() << endl;
		return;
	}


	// client information 
	sockaddr_in client;
	int clientLength = sizeof(client); 

	char buf[1024];


	while (true)
	{

		ZeroMemory(&client, clientLength); 
		ZeroMemory(buf, 1024); 

		// Wait for message
		int bytesIn = recvfrom(in, buf, 1024, 0, (sockaddr*)&client, &clientLength);
		if (bytesIn == SOCKET_ERROR)
		{
			cout << "Error receiving from client " << WSAGetLastError() << endl;
			continue;
		}

		// Display message and client info
		char clientIp[256]; 
		ZeroMemory(clientIp, 256); 
		// Convert from byte array to chars
		inet_ntop(AF_INET, &client.sin_addr, clientIp, 256);

		cout << "Message received from " << clientIp << " : " << buf << endl;
		

	}



	closesocket(in);

	
	WSACleanup();
}
