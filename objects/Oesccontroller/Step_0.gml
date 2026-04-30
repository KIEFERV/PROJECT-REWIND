/// Step_0 — oEscController
/// Tracks room changes and handles global ESC navigation.

// ── Track room transitions — push to history when room changes ────────────
if (!variable_instance_exists(id, "_last_room")) _last_room = room;

if (room != _last_room) {
    // Only push rooms we can go back to (not blocked rooms)
    var _was_blocked = false;
    for (var _i = 0; _i < array_length(esc_blocked_rooms); _i++) {
        if (_last_room == esc_blocked_rooms[_i]) { _was_blocked = true; break; }
    }
    if (!_was_blocked) {
        ds_stack_push(esc_history, _last_room);
    }
    _last_room = room;
}

// ── ESC handling ──────────────────────────────────────────────────────────
if (!keyboard_check_pressed(vk_escape)) exit;

// Check if current room blocks ESC
var _blocked = false;
for (var _i = 0; _i < array_length(esc_blocked_rooms); _i++) {
    if (room == esc_blocked_rooms[_i]) { _blocked = true; break; }
}
if (_blocked) exit;

// Also block if in loadout during multiplayer (oLobby not present but socket active)
if (room == rm_loadout && global.socket >= 0) exit;

// Go back to previous room
if (!ds_stack_empty(esc_history)) {
    var _prev = ds_stack_pop(esc_history);
    room_goto(_prev);
} else {
    // No history — fall back to menu
    if (room != rm_menu) room_goto(rm_menu);
}
