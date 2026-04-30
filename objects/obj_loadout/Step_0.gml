var gui_w = display_get_gui_width();
var gui_h = display_get_gui_height();

var panel_w = 860;
var panel_h = 600;
var panel_x = (gui_w - panel_w) / 2;
var panel_y = (gui_h - panel_h) / 2;

var play_x = panel_x + 520;
var play_y = panel_y + 520;
var back_x = panel_x + 330;
var back_y = panel_y + 520;

var mx = device_mouse_x_to_gui(0);
var my = device_mouse_y_to_gui(0);

hover_play = point_in_rectangle(mx, my, play_x, play_y, play_x + button_w, play_y + button_h);
hover_back = point_in_rectangle(mx, my, back_x, back_y, back_x + button_w, back_y + button_h);

<<<<<<< HEAD
=======
// ── If already locked in, just wait for server ────────────────────────────
if (variable_instance_exists(id, "locked_in") && locked_in) exit;

// ── Column switching ──────────────────────────────────────────────────────
>>>>>>> parent of 7349df5 (Merge pull request #53 from KIEFERV/round-logic)
if (keyboard_check_pressed(vk_tab)) {
    active_column = 1 - active_column;
}

<<<<<<< HEAD
=======
// ── Navigate selection ────────────────────────────────────────────────────
>>>>>>> parent of 7349df5 (Merge pull request #53 from KIEFERV/round-logic)
if (keyboard_check_pressed(vk_up)) {
    if (active_column == 0) {
        primary_index--;
        if (primary_index < 0) primary_index = array_length(primary_list) - 1;
    } else {
        secondary_index--;
        if (secondary_index < 0) secondary_index = array_length(secondary_list) - 1;
    }
}
if (keyboard_check_pressed(vk_down)) {
    if (active_column == 0) {
        primary_index++;
        if (primary_index >= array_length(primary_list)) primary_index = 0;
    } else {
        secondary_index++;
        if (secondary_index >= array_length(secondary_list)) secondary_index = 0;
    }
}

<<<<<<< HEAD
if (keyboard_check_pressed(vk_enter) || (hover_play && mouse_check_button_pressed(mb_left))) {
    global.primary_weapon   = primary_list[primary_index];
    global.secondary_weapon = secondary_list[secondary_index];
    room_goto(rMovementTesting);
=======
// ── Lock in / Start ───────────────────────────────────────────────────────
if (keyboard_check_pressed(vk_enter) || (hover_play && mouse_check_button_pressed(mb_left))) {
    global.primary_weapon   = primary_list[primary_index];
    global.secondary_weapon = secondary_list[secondary_index];

    // Check if we're in a multiplayer match (socket exists)
    if (global.socket >= 0) {
        // Multiplayer — send ready packet and wait for all players
        locked_in   = true;
        status_text = "Locked in! Waiting for other players...";

        var _buf = buffer_create(1, buffer_fixed, 1);
        buffer_write(_buf, buffer_u8, 14);  // PKT_LOADOUT_READY
        network_send_udp_raw(global.socket, global.ip_address, global.port, _buf, 1);
        buffer_delete(_buf);

        show_debug_message("Loadout locked: " + global.primary_weapon
            + " / " + global.secondary_weapon);
    } else {
        // Solo / practice — go straight to game
        room_goto(rMovementTesting);
    }
>>>>>>> parent of 7349df5 (Merge pull request #53 from KIEFERV/round-logic)
}

if (keyboard_check_pressed(vk_escape) || (hover_back && mouse_check_button_pressed(mb_left))) {
<<<<<<< HEAD
    room_goto(rm_menu);
=======
    if (global.socket >= 0) {
        room_goto(rLobby);  // multiplayer — back to lobby
    } else {
        room_goto(rm_menu); // solo — back to menu
    }
>>>>>>> parent of 7349df5 (Merge pull request #53 from KIEFERV/round-logic)
}
