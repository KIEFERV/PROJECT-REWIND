/// CleanUp_0 — oLobby
/// Only sends disconnect if we're leaving the lobby to go back to the browser,
/// NOT if we're transitioning to the loadout/match (socket is handed off).

if (ds_exists(lobby_players, ds_type_map))
    ds_map_destroy(lobby_players);

// Don't disconnect if transitioning to loadout or match
var _going_to_match = variable_global_exists("going_to_match") && global.going_to_match;

if (socket >= 0 && global.socket != socket && !_going_to_match) {
    var _buf = buffer_create(1, buffer_fixed, 1);
    buffer_write(_buf, buffer_u8, 9);  // type 9 = disconnect
    network_send_udp_raw(socket, global.ip_address, global.port, _buf, 1);
    buffer_delete(_buf);
    network_destroy(socket);
    socket = -1;
}

// Reset flag
if (variable_global_exists("going_to_match"))
    global.going_to_match = false;
