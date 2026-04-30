/// Other_68 (Async - Networking) — obj_loadout

if (async_load[? "type"] != network_type_data) exit;

var _buf = async_load[? "buffer"];
buffer_seek(_buf, buffer_seek_start, 0);
var _ptype = buffer_read(_buf, buffer_u8);

// Type 18 — countdown tick
// When value hits 0 (GO), transition to match
if (_ptype == 18) {
    var _count = buffer_read(_buf, buffer_u8);
    show_debug_message("Loadout countdown: " + string(_count));
    if (_count == 0) {
        show_debug_message("GO — entering match!");
        global.match_phase     = "playing";
        global.countdown_value = 0;
        room_goto(rMovementTesting);
    } else {
        global.match_phase     = "countdown";
        global.countdown_value = _count;
    }
    exit;
}

// Type 13 — player list (ignore)
if (_ptype == 13) exit;

// Type 15 — all ready (now redundant, ignore safely)
if (_ptype == 15) exit;

// Type 3 — player disconnected
if (_ptype == 3) {
    var _left_pid = buffer_read(_buf, buffer_u16);
    if (_left_pid == 1 && global.my_pid != 1) {
        room_goto(rLobby);
    }
    exit;
}
