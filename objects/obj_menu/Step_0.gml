hover_index = -1;

var gui_mx = device_mouse_x_to_gui(0);
var gui_my = device_mouse_y_to_gui(0);

var gui_w = display_get_gui_width();
var gui_h = display_get_gui_height();

var panel_w = 980;
var panel_h = 620;
var panel_x = (gui_w - panel_w) / 2;
var panel_y = (gui_h - panel_h) / 2;

var left_x = panel_x + 50;
var start_y = panel_y + 140;

var logged_in = (global.auth_token != "");

for (var i = 0; i < array_length(menu_buttons); i++) {
    var bx1 = left_x;
    var by1 = start_y + i * (button_h + button_gap);
    var bx2 = bx1 + button_w;
    var by2 = by1 + button_h;

    var disabled = (menu_buttons[i].requires_login && !logged_in);

    if (point_in_rectangle(gui_mx, gui_my, bx1, by1, bx2, by2)) {
        hover_index = i;

        if (disabled) {
            status_text = "Login required for " + menu_buttons[i].label;
        } else {
            status_text = menu_buttons[i].desc;
        }

        if (mouse_check_button_pressed(mb_left) && !disabled) {
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
if (keyboard_check_pressed(vk_enter)) {
    room_goto(rm_game);
}

if (keyboard_check_pressed(ord("L"))) room_goto(rm_login);
if (keyboard_check_pressed(ord("R"))) room_goto(rm_register);
if (keyboard_check_pressed(ord("B"))) room_goto(rm_browse_lobbies);
if (keyboard_check_pressed(ord("T"))) room_goto(rm_leaderboard);

if (logged_in && keyboard_check_pressed(ord("C"))) {
    room_goto(rm_create_lobby);
}