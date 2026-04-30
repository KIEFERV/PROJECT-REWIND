/// Step_0 — oEscController

// ── Track room transitions ────────────────────────────────────────────────
if (!variable_instance_exists(id, "_last_room")) _last_room = room;

if (room != _last_room) {
    // Clear history when returning to menu — fresh start
    if (room == rm_menu) {
        ds_stack_clear(esc_history);
    } else {
        // Push previous room unless it's blocked, the menu, or a skip room
        var _was_blocked = (_last_room == rm_menu);
        for (var _i = 0; _i < array_length(esc_blocked_rooms); _i++) {
            if (_last_room == esc_blocked_rooms[_i]) { _was_blocked = true; break; }
        }
        for (var _i = 0; _i < array_length(esc_skip_rooms); _i++) {
            if (_last_room == esc_skip_rooms[_i]) { _was_blocked = true; break; }
        }
        if (!_was_blocked) {
            ds_stack_push(esc_history, _last_room);
        }
    }
    _last_room = room;
}

// ── ESC handling ──────────────────────────────────────────────────────────
if (!keyboard_check_pressed(vk_escape)) exit;

// Never go back from the menu
if (room == rm_menu) exit;

// Check blocked rooms
var _blocked = false;
for (var _i = 0; _i < array_length(esc_blocked_rooms); _i++) {
    if (room == esc_blocked_rooms[_i]) { _blocked = true; break; }
}
if (_blocked) exit;

// Block in loadout during multiplayer
if (room == rm_loadout && global.socket >= 0) exit;

// Go back or fall to menu
if (!ds_stack_empty(esc_history)) {
    var _prev = ds_stack_pop(esc_history);
    room_goto(_prev);
} else {
    if (room != rm_menu) room_goto(rm_menu);
}
