/// Step_0 — obj_menu

hover_index = -1;

var gui_mx = device_mouse_x_to_gui(0);
var gui_my = device_mouse_y_to_gui(0);

var gui_w   = display_get_gui_width();
var gui_h   = display_get_gui_height();
var panel_w = 980;
var panel_h = 620;
var panel_x = (gui_w - panel_w) / 2;
var panel_y = (gui_h - panel_h) / 2;
var left_x  = panel_x + 50;
var start_y = panel_y + 140;

var logged_in = (global.auth_token != "");

// Track visible button positions (skip hidden ones)
var visible_y = start_y;

for (var i = 0; i < array_length(menu_buttons); i++) {
    var btn = menu_buttons[i];

    // Hide login/register when logged in
    var hidden = variable_struct_exists(btn, "hide_when_logged_in")
                 && btn.hide_when_logged_in && logged_in;
    if (hidden) continue;

    var bx1 = left_x;
    var by1 = visible_y;
    var bx2 = bx1 + button_w;
    var by2 = by1 + button_h;
    visible_y += button_h + button_gap;

    var disabled = (btn.requires_login && !logged_in);

    if (point_in_rectangle(gui_mx, gui_my, bx1, by1, bx2, by2)) {
        hover_index = i;

        if (disabled) {
            status_text = "Login required for " + btn.label;
        } else {
            status_text = btn.desc;
        }

        if (mouse_check_button_pressed(mb_left) && !disabled) {
            switch (btn.action) {
                case "room":
                    // Reset socket if going to practice (loadout)
                    if (btn.target == rm_loadout) {
                        global.socket     = -1;
                        global.ip_address = "";
                        global.port       = 0;
                    }
                    room_goto(btn.target);
                break;
                case "logout":
                    global.auth_token = "";
                    global.username   = "";
                    global.user_role  = "";
                    global.user_id    = "";
                    room_goto(btn.target);
                break;
            }
        }
    }
}

// Keyboard shortcuts
if (keyboard_check_pressed(vk_enter)) {
    // Practice Room — reset socket so loadout knows it's solo
    global.socket     = -1;
    global.ip_address = "";
    global.port       = 0;
    room_goto(rm_loadout);
}
if (keyboard_check_pressed(ord("P"))) room_goto(rLobbyBrowser);
if (keyboard_check_pressed(ord("T"))) room_goto(rm_leaderboard);
if (!logged_in && keyboard_check_pressed(ord("L"))) room_goto(rm_login);
if (!logged_in && keyboard_check_pressed(ord("R"))) room_goto(rm_register);
