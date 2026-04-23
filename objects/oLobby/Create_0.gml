/// Create_0 — oLobby
///
/// Creates a fresh socket and sends a type-10 join request.
/// The server assigns pid=1 to the first client, pid=2 to the second, etc.
/// is_host is set in Other_68 when the server's type-2 pid response arrives.

is_host      = false;
my_pid       = 0;
status_msg   = "Connecting to server...";
player_count = 1;

// Always create a fresh socket
socket = network_create_socket(network_socket_udp);

show_debug_message("oLobby Create: socket=" + string(socket)
    + " -> " + global.ip_address + ":" + string(global.port));

// Send type-10 join request to register with the game server
var _buf = buffer_create(1, buffer_fixed, 1);
buffer_write(_buf, buffer_u8, 10);
network_send_udp_raw(socket, global.ip_address, global.port, _buf, buffer_tell(_buf));
buffer_delete(_buf);

// Clear flag — is_host is determined solely by server pid response
global.is_creating_lobby = false;
