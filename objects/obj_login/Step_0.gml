hover_login = false;
hover_register = false;

var gui_mx = device_mouse_x_to_gui(0);
var gui_my = device_mouse_y_to_gui(0);

var gui_w = display_get_gui_width();
var gui_h = display_get_gui_height();

var panel_w = 440;
var panel_h = 320;
var panel_x = (gui_w - panel_w) / 2;
var panel_y = (gui_h - panel_h) / 2;

// field positions
var user_y = panel_y + 95;
var pass_y = panel_y + 160;

// mouse field focus
if (mouse_check_button_pressed(mb_left)) {
    if (point_in_rectangle(gui_mx, gui_my, panel_x + 30, user_y, panel_x + panel_w - 30, user_y + 35)) {
        active_field = 0;
    }

    if (point_in_rectangle(gui_mx, gui_my, panel_x + 30, pass_y, panel_x + panel_w - 30, pass_y + 35)) {
        active_field = 1;
    }
}

// tab switch
if (keyboard_check_pressed(vk_tab)) {
    active_field = 1 - active_field;
}

// backspace
if (keyboard_check_pressed(vk_backspace)) {
    if (active_field == 0 && string_length(username_text) > 0) {
        username_text = string_delete(username_text, string_length(username_text), 1);
    }

    if (active_field == 1 && string_length(password_text) > 0) {
        password_text = string_delete(password_text, string_length(password_text), 1);
    }
}

// safe typing
var c = keyboard_lastchar;

if (c != "" && c != last_char_used) {
    var code = ord(c);

    if (code >= 32 && code <= 126) {
        if (active_field == 0 && string_length(username_text) < 24) {
            username_text += c;
        }

        if (active_field == 1 && string_length(password_text) < 24) {
            password_text += c;
        }
    }

    last_char_used = c;
}

if (keyboard_lastchar == "") {
    last_char_used = "";
}

// button positions
var login_x = panel_x + 40;
var login_y = panel_y + 225;

var register_x = panel_x + 220;
var register_y = panel_y + 225;

// hover states
if (point_in_rectangle(gui_mx, gui_my, login_x, login_y, login_x + button_w, login_y + button_h)) {
    hover_login = true;
}

if (point_in_rectangle(gui_mx, gui_my, register_x, register_y, register_x + button_w, register_y + button_h)) {
    hover_register = true;
}

// login action
var do_login = false;

if (keyboard_check_pressed(vk_enter)) {
    do_login = true;
}

if (hover_login && mouse_check_button_pressed(mb_left)) {
    do_login = true;
}

if (do_login) {
    if (username_text == "" || password_text == "") {
        status_text = "Username and password are required.";
    } else {
        status_text = "Logging in...";

        // Supabase auth uses email — we treat username field as email
        var body = json_stringify({
            email:    username_text,
            password: password_text
        });

        // Supabase signInWithPassword endpoint
        var headers = ds_map_create();
        ds_map_add(headers, "Content-Type",  "application/json");
        ds_map_add(headers, "apikey",        SUPABASE_ANON_KEY);
        login_request_id = http_request(
            SUPABASE_URL_AUTH + "/auth/v1/token?grant_type=password",
            "POST",
            headers,
            body
        );
        ds_map_destroy(headers);
    }
}

// register button action
if (hover_register && mouse_check_button_pressed(mb_left)) {
    room_goto(rm_register);
}
if (keyboard_check_pressed(vk_escape)) {
    room_goto(rm_menu);
}