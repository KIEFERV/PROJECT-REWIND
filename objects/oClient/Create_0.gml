client = network_create_socket(network_socket_udp);
network_set_config(network_config_connect_timeout, 1000);

player_buffer = buffer_create(256,buffer_grow,1);
network_connect_raw(client, "127.0.0.1", 54000); //connect raw due to non-gamemaker server


