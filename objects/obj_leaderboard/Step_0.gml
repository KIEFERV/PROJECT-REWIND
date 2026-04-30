/// Step_0 — obj_leaderboard

hover_back    = false;
hover_refresh = false;

var gui_mx = device_mouse_x_to_gui(0);
var gui_my = device_mouse_y_to_gui(0);
var gui_w  = display_get_gui_width();
var gui_h  = display_get_gui_height();

var panel_w = 820;
var panel_h = 520;
var panel_x = (gui_w - panel_w) / 2;
var panel_y = (gui_h - panel_h) / 2;

var back_x    = panel_x + 30;
var back_y    = panel_y + panel_h - 55;
var refresh_x = panel_x + 185;
var refresh_y = back_y;

// Back button
if (point_in_rectangle(gui_mx, gui_my, back_x, back_y, back_x + button_w, back_y + button_h)) {
    hover_back = true;
    if (mouse_check_button_pressed(mb_left)) room_goto(rm_menu);
}

// Refresh button
if (point_in_rectangle(gui_mx, gui_my, refresh_x, refresh_y, refresh_x + button_w, refresh_y + button_h)) {
    hover_refresh = true;
    if (mouse_check_button_pressed(mb_left)) {
        leaderboard_data   = [];
        status_text        = "Refreshing...";
        var _headers = ds_map_create();
        ds_map_add(_headers, "apikey",        SUPABASE_ANON_KEY);
        ds_map_add(_headers, "Authorization", "Bearer " + SUPABASE_ANON_KEY);
        ds_map_add(_headers, "Content-Type",  "application/json");
        leaderboard_request_id = http_request(
            SUPABASE_URL_AUTH + "/rest/v1/profiles"
            + "?select=username,wins,kills,deaths"
            + "&order=wins.desc,kills.desc"
            + "&limit=20",
            "GET",
            _headers,
            ""
        );
        ds_map_destroy(_headers);
    }
}

if (keyboard_check_pressed(vk_escape)) room_goto(rm_menu);
