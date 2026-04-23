/// Create_0 — oLobby
///
/// Always creates a fresh socket and sends a type-10 join request.
/// The server assigns pid=1 to the first client that connects — which will
/// always be the host, since oLobbyBrowser launches server.exe and
/// immediately transitions to rLobby before any other client can join.
///
/// global.is_creating_lobby (set by oLobbyBrowser) tells us to show the
/// host UI immediately while we wait for the pid-2 confirmation.

is_host    = false;
my_pid     = 0;
status_msg = "Connecting to server...";
player_count = 1;

// Always create a fresh socket — no socket hand-off between objects.
// This guarantees a stable OS-level source port for the life of the lobby.
socket = network_create_socket(network_socket_udp);

show_debug_message("oLobby: socket=" + string(socket)
    + " -> " + global.ip_address + ":" + string(global.port));

// Send type-10 join request to register with the game server
var _buf = buffer_create(4, buffer_grow, 1);
buffer_seek(_buf, buffer_seek_start, 0);
buffer_write(_buf, buffer_u8, 10);
network_send_udp_raw(socket, global.ip_address, global.port,
                     _buf, buffer_tell(_buf));
buffer_delete(_buf);

// If we created this lobby show a temporary status while waiting for pid ack.
// is_host is NOT set here — it is set authoritatively when the server sends
// pid=1 in the type-2 packet, so both host and joiner go through the same path.
if (global.is_creating_lobby) {
    status_msg = "Waiting for server...";
    show_debug_message("oLobby: host path — waiting for pid ack.");
}

// Clear the flag so rejoining later doesn't falsely trigger the host path
global.is_creating_lobby = false;
