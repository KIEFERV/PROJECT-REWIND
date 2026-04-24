/// Create_0 — oLobby

is_host      = false;
my_pid       = 0;
status_msg   = "Connecting to server...";
player_count = 1;

socket = network_create_socket(network_socket_udp);

show_debug_message("=== oLobby Create ===");
show_debug_message("  socket=" + string(socket));
show_debug_message("  ip=" + global.ip_address);
show_debug_message("  port=" + string(global.port));
show_debug_message("  is_creating_lobby=" + string(global.is_creating_lobby));

var _buf = buffer_create(1, buffer_fixed, 1);
buffer_write(_buf, buffer_u8, 10);
network_send_udp_raw(socket, global.ip_address, global.port, _buf, buffer_tell(_buf));
buffer_delete(_buf);

global.is_creating_lobby = false;