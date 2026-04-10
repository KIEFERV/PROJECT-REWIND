// Create Event
socket = network_create_socket(network_socket_udp);

if (socket < 0) {
    show_debug_message("Failed to create socket!");
} else {
	var ip = global.ip_address,
		port = global.port;
    show_debug_message("Socket created: " + string(socket));
    var result = network_connect_raw(socket, ip, port);
    show_debug_message("Connect result: " + string(result));
}

other_players = ds_map_create();

time_remaining = 180;