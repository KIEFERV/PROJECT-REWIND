client = network_create_socket(network_socket_udp);
network_connect_raw(client, "127.0.0.1", 54000)


player_buffer = buffer_create(100, buffer_fixed, 100);