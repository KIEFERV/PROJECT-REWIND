ip = "108.29.130.112"
port = 5400;


//create UDP socket
socket = network_create_socket(network_socket_udp);
network_connect_raw(socket,ip, port);

buffer = buffer_create(256, buffer_fixed, 100);
