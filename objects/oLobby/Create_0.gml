socket = network_create_socket(network_socket_udp);
//network_connect_raw(socket, global.ip_address, global.port);
player_count = 1;
is_host = false;
status_msg = "Waiting for server...";
show_debug_message("Socket created: " + string(socket) +
	" connecting to " + global.ip_address + ":" + string(global.port));

// Manually send a join packet to register with the server
var buf = buffer_create(4, buffer_grow, 1);
buffer_seek(buf, buffer_seek_start, 0);
buffer_write(buf, buffer_u8, 10);  // type 10 = join request
network_send_udp_raw(socket, global.ip_address, global.port, buf, buffer_tell(buf));
buffer_delete(buf);