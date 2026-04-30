/// Other_68 (Async - Networking) — obj_loadout
/// Listens for PKT_ALL_READY (type 15) from the server.
/// When received, all players transition to the game room.

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

// Type 3 — a player disconnected while in loadout
if (_ptype == 3) {
    status_msg = "A player disconnected. Returning to lobby...";
    show_debug_message("Player left during loadout — returning to lobby.");
    alarm[0] = game_get_speed(gamespeed_fps) * 2;
    exit;
}
