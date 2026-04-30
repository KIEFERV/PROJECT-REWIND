/// Other_68 (Async - Networking) — obj_loadout
/// Keeps the connection alive and listens for PKT_ALL_READY (type 15).

if (async_load[? "type"] != network_type_data) exit;

var _buf = async_load[? "buffer"];
buffer_seek(_buf, buffer_seek_start, 0);
var _ptype = buffer_read(_buf, buffer_u8);

// Type 15 — all players locked in, match starting
if (_ptype == 15) {
    show_debug_message("All players ready — entering match!");
    room_goto(rMovementTesting);
    exit;
}

// Type 13 — player list update (ignore in loadout)
if (_ptype == 13) exit;

// Type 3 — a player disconnected while in loadout
if (_ptype == 3) {
    var _left_pid = buffer_read(_buf, buffer_u16);
    show_debug_message("Player pid=" + string(_left_pid) + " left during loadout.");
    // Only go back to lobby if the host left
    if (_left_pid == 1 && global.my_pid != 1) {
        show_debug_message("Host left during loadout — returning to lobby.");
        room_goto(rLobby);
    }
    exit;
}

// Silently ignore all other packet types (keepalive echoes, etc.)
