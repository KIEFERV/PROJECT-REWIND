// Go to register screen
hover_index = -1;

var gui_mx = device_mouse_x_to_gui(0);
var gui_my = device_mouse_y_to_gui(0);

var gui_w = display_get_gui_width();
var gui_h = display_get_gui_height();

var panel_w = 900;
var panel_h = 500;
var panel_x = (gui_w - panel_w) / 2;
var panel_y = (gui_h - panel_h) / 2;

var left_x = panel_x + 50;
var start_y = panel_y + 145;

for (var i = 0; i < array_length(menu_buttons); i++) {
    var bx1 = left_x;
    var by1 = start_y + i * (button_h + button_gap);
    var bx2 = bx1 + button_w;
    var by2 = by1 + button_h;

    if (point_in_rectangle(gui_mx, gui_my, bx1, by1, bx2, by2)) {
        hover_index = i;
        status_text = menu_buttons[i].desc;

        if (mouse_check_button_pressed(mb_left)) {
            switch (menu_buttons[i].action) {
                case "room":
                    room_goto(menu_buttons[i].target);
                break;

                case "logout":
                    global.auth_token = "";
                    global.username = "";
                    global.user_role = "";
                    room_goto(menu_buttons[i].target);
                break;
            }
        }
    }
}

// Keyboard shortcuts
if (keyboard_check_pressed(ord("L"))) room_goto(rm_login);
if (keyboard_check_pressed(ord("R"))) room_goto(rm_register);
if (keyboard_check_pressed(ord("C"))) room_goto(rm_create_lobby);
if (keyboard_check_pressed(ord("B"))) room_goto(rm_browse_lobbies);