var gui_w = display_get_gui_width();
var gui_h = display_get_gui_height();
var mx    = device_mouse_x_to_gui(0);
var my    = device_mouse_y_to_gui(0);

var panel_w   = 860;
var panel_h   = 600;
var panel_x   = (gui_w - panel_w) / 2;
var panel_top = (gui_h - panel_h) / 2;
var col1_x    = panel_x + 70;
var col2_x    = panel_x + 450;
var list_top  = panel_top + 120;
var row_h     = 42;
var row_w     = 310;
var play_x    = panel_x + 520;
var play_y    = panel_top + 520;
var back_x    = panel_x + 330;
var back_y    = panel_top + 520;

// ── Keepalive ─────────────────────────────────────────────────────────────
keepalive_timer++;
if (keepalive_timer >= game_get_speed(gamespeed_fps) * 2) {
    keepalive_timer = 0;
    if (global.socket >= 0) {
        var _kbuf = buffer_create(1, buffer_fixed, 1);
        buffer_write(_kbuf, buffer_u8, 12);
        network_send_udp_raw(global.socket, global.ip_address, global.port, _kbuf, 1);
        buffer_delete(_kbuf);
    }
}

// ── If locked in, just wait for server ───────────────────────────────────
if (locked_in) exit;

var _clicked = mouse_check_button_pressed(mb_left);

// ── Click primary weapon rows ─────────────────────────────────────────────
for (var i = 0; i < array_length(primary_list); i++) {
    var row_top = list_top + i * row_h;
    if (_clicked && point_in_rectangle(mx, my, col1_x, row_top, col1_x + row_w, row_top + 32)) {
        primary_index = i;
        active_column = 0;
    }
}

// ── Click secondary weapon rows ───────────────────────────────────────────
for (var j = 0; j < array_length(secondary_list); j++) {
    var row_top2 = list_top + j * row_h;
    if (_clicked && point_in_rectangle(mx, my, col2_x, row_top2, col2_x + row_w, row_top2 + 32)) {
        secondary_index = j;
        active_column   = 1;
    }
}

// ── Keyboard navigation still works ──────────────────────────────────────
if (keyboard_check_pressed(vk_tab)) active_column = 1 - active_column;

if (keyboard_check_pressed(vk_up)) {
    if (active_column == 0) {
        primary_index = (primary_index - 1 + array_length(primary_list)) mod array_length(primary_list);
    } else {
        secondary_index = (secondary_index - 1 + array_length(secondary_list)) mod array_length(secondary_list);
    }
}
if (keyboard_check_pressed(vk_down)) {
    if (active_column == 0) {
        primary_index = (primary_index + 1) mod array_length(primary_list);
    } else {
        secondary_index = (secondary_index + 1) mod array_length(secondary_list);
    }
}

// ── Lock In — ENTER or click button ──────────────────────────────────────
var _lock_clicked = _clicked && point_in_rectangle(mx, my, play_x, play_y, play_x + button_w, play_y + button_h);

if (keyboard_check_pressed(vk_enter) || _lock_clicked) {
    global.primary_weapon   = primary_list[primary_index];
    global.secondary_weapon = secondary_list[secondary_index];

    if (global.socket >= 0) {
        locked_in   = true;
        status_text = "Locked in! Waiting for other players...";
        show_debug_message("Sending type-14 to " + string(global.ip_address) + ":" + string(global.port) + " socket=" + string(global.socket));
        show_debug_message("ENTER pressed in loadout. locked_in=" + string(locked_in) + " socket=" + string(global.socket));
        var _buf = buffer_create(1, buffer_fixed, 1);
        buffer_write(_buf, buffer_u8, 14);
        network_send_udp_raw(global.socket, global.ip_address, global.port, _buf, 1);
        buffer_delete(_buf);
        locked_in = true;
        show_debug_message("Loadout locked: " + global.primary_weapon + " / " + global.secondary_weapon);
    } else {
        room_goto(rMovementTesting);
    }
}

// ── Back — ESC or click button ────────────────────────────────────────────
var _back_clicked = _clicked && point_in_rectangle(mx, my, back_x, back_y, back_x + button_w, back_y + button_h);

if (keyboard_check_pressed(vk_escape) || _back_clicked) {
    if (global.socket >= 0) {
        room_goto(rLobby);
    } else {
        room_goto(rm_menu);
    }
}
