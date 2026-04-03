// Create Event
socket = network_create_socket(network_socket_udp);

if (socket < 0) {
    show_debug_message("Failed to create socket!");
} else {
    show_debug_message("Socket created: " + string(socket));
    var result = network_connect_raw(socket, "127.0.0.1", 7777);
    show_debug_message("Connect result: " + string(result));
}

other_players = ds_map_create();