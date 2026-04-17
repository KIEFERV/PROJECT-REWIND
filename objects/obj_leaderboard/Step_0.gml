hover_back = false;

var gui_mx = device_mouse_x_to_gui(0);
var gui_my = device_mouse_y_to_gui(0);

var gui_w = display_get_gui_width();
var gui_h = display_get_gui_height();

var panel_w = 820;
var panel_h = 500;
var panel_x = (gui_w - panel_w) / 2;
var panel_y = (gui_h - panel_h) / 2;

var back_x = panel_x + 30;
var back_y = panel_y + panel_h - 60;

if (point_in_rectangle(gui_mx, gui_my, back_x, back_y, back_x + button_w, back_y + button_h)) {
    hover_back = true;

    if (mouse_check_button_pressed(mb_left)) {
        room_goto(rm_menu);
    }
}

if (keyboard_check_pressed(vk_escape)) {
    room_goto(rm_menu);
}