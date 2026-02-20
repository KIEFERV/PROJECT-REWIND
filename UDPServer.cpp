#include <iostream> //output to console
#include <ws2tcpip.h> //function errors for window socket library

#pragma comment (lib, "ws2_32.lib")

using namespace std; //<- no need for std::out with this

void main()
{
//winsock
	WSADATA data; //winsock data
	WORD version = MAKEWORD(2, 2); 
	int wsOk = WSAStartup(version, &data); //winsock version
	if (wsOk != 0)
	{
		cout << "Winsock could not start" << wsOk;
		return;
	}
//bind socket to ip address and port
	SOCKET in = socket(AF_INET, SOCK_DGRAM, 0); //creating a socket
	sockaddr_in serverHint; 
	serverHint.sin_addr.S_un.S_addr = ADDR_ANY; //give any server address
	serverHint.sin_family = AF_INET;
	serverHint.sin_port = htons(5400); //Convert from little to big endian, port 54000  htons = host to network short 

	//bind socket to serverhint
		if (bind(in, (sockaddr*)&serverHint, sizeof(serverHint)) == SOCKET_ERROR)
		{
			cout << "Socket was not bound " << WSAGetLastError() << endl;
			return;
	}
		sockaddr_in client; //client that is connecting; client metadata
		ZeroMemory(&client, sizeof(client)); //client information
		int clientLength = sizeof(client);

		char buf[1024];


//enter a loop
		while (true)
		{
			ZeroMemory(buf, 1024); //buffer where message gets received into
			//wait for message
			int bytesIn = recvfrom(in, buf, 1024, 0, (sockaddr*)&client, &clientLength); //fills in buffer and then fills in client metadata
			if (bytesIn == SOCKET_ERROR)
			{
				cout << "Error receiving from client" << WSAGetLastError() << endl;
				continue;
			}
			//Display message and client info
			char clientIP[256];
			ZeroMemory(clientIP, 256);

			inet_ntop(AF_INET, &client.sin_addr, clientIP, 256);  //get client information into a printable form; ntop = number two pointed to a string 

			cout << "Message recv from " << clientIP << " : " << buf << endl; //display information in a message
		}
	//Close socket 
		closesocket(in);
	//Shutdown windows sockets
	WSACleanup();
}