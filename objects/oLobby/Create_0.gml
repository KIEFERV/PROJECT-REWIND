/// Create_0 — oLobby
///
/// Sends a type-10 join request with user_id and username so the server
/// can track stats per authenticated player.
/// Packet: [u8:10][lpstr:user_id][lpstr:username]

is_host      = false;
my_pid       = 0;
status_msg   = "Connecting to server...";
player_count = 1;

// Map of pid -> username for all players in the lobby
// Updated when server sends type-13 PKT_PLAYER_LIST
lobby_players = ds_map_create();

socket = network_create_socket(network_socket_udp);

show_debug_message("=== oLobby Create ===");
show_debug_message("  socket="    + string(socket));
show_debug_message("  ip="        + global.ip_address);
show_debug_message("  port="      + string(global.port));
show_debug_message("  user_id="   + global.user_id);
show_debug_message("  username="  + global.username);

// Build join packet with identity
var _uid  = global.user_id;   // Supabase UUID or "" for guest
var _name = global.username;  // display name or "" for guest
if (_name == "") _name = "Guest";

var _buf = buffer_create(128, buffer_grow, 1);
buffer_write(_buf, buffer_u8, 10);  // type 10 = join request

// Write user_id (length-prefixed string)
var _uid_len = min(string_length(_uid), 63);
buffer_write(_buf, buffer_u8, _uid_len);
for (var _i = 1; _i <= _uid_len; _i++)
    buffer_write(_buf, buffer_u8, ord(string_char_at(_uid, _i)));

// Write username (length-prefixed string)
var _name_len = min(string_length(_name), 31);
buffer_write(_buf, buffer_u8, _name_len);
for (var _i = 1; _i <= _name_len; _i++)
    buffer_write(_buf, buffer_u8, ord(string_char_at(_name, _i)));

network_send_udp_raw(socket, global.ip_address, global.port, _buf, buffer_tell(_buf));
buffer_delete(_buf);

// Clear flag — is_host is set authoritatively from server pid response
global.is_creating_lobby = false;
