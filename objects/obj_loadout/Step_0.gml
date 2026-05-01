show_debug_message("Sending type-14 to " + string(global.ip_address) + ":" + string(global.port) + " socket=" + string(global.socket));
show_debug_message("ENTER pressed in loadout. locked_in=" + string(locked_in) + " socket=" + string(global.socket));
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

if (keyboard_check_pressed(vk_tab)) {
    active_column = 1 - active_column;
}

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

if (keyboard_check_pressed(vk_enter) || (hover_play && mouse_check_button_pressed(mb_left))) {
    global.primary_weapon   = primary_list[primary_index];
    global.secondary_weapon = secondary_list[secondary_index];
    room_goto(rMovementTesting);
}

if (keyboard_check_pressed(vk_escape) || (hover_back && mouse_check_button_pressed(mb_left))) {
    room_goto(rm_menu);
}
