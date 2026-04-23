/// Draw_64 (Draw GUI) — oLobbyBrowser

var _gw = display_get_gui_width();
var _gh = display_get_gui_height();
var _cx = _gw / 2;
var _cy = _gh / 2;

draw_set_font(-1);
draw_set_halign(fa_center);
draw_set_valign(fa_top);

// ════════════════════════════════════════════════════════════════════════════
//  SCREEN: SETUP
// ════════════════════════════════════════════════════════════════════════════
if (current_screen == SCREEN_SETUP) {
    draw_set_color(c_black);
    draw_set_alpha(1);
    draw_rectangle(0, 0, _gw, _gh, false);

    draw_set_halign(fa_center);
    draw_set_color(c_white);
    draw_text(_cx, _cy - 60, "NETWORK SETUP");

    draw_set_color(c_ltgray);
    draw_text(_cx, _cy - 20, status_msg);

    if (setup_phase == 0) {
        draw_set_color(c_dkgray);
        draw_text(_cx, _cy + 20, "Starting...");
    } else if (setup_phase == 1) {
        draw_set_color(c_yellow);
        draw_text(_cx, _cy + 20, "If a Windows Security Alert appears,");
        draw_text(_cx, _cy + 44, "click "Allow Access" to enable multiplayer.");
        draw_set_color(c_dkgray);
        draw_text(_cx, _cy + 80, "Press any key to continue once done.");
    }

    var _dots = string_repeat(".", (current_time div 400) mod 4);
    draw_set_color(c_dkgray);
    draw_text(_cx, _cy + 110, _dots);
    exit;
}

// ════════════════════════════════════════════════════════════════════════════
//  LAUNCH OVERLAY
// ════════════════════════════════════════════════════════════════════════════
if (launching) {
    draw_set_color(c_black);
    draw_set_alpha(0.80);
    draw_rectangle(0, 0, _gw, _gh, false);
    draw_set_alpha(1);
    draw_set_color(c_white);
    draw_text(_cx, _cy - 12, status_msg);
    draw_set_color(c_ltgray);
    draw_text(_cx, _cy + 14, string_repeat(".", (current_time div 250) mod 4));
    exit;
}

// ════════════════════════════════════════════════════════════════════════════
//  SCREEN: MODE SELECT
// ════════════════════════════════════════════════════════════════════════════
if (current_screen == SCREEN_MODE) {

    draw_set_color(c_white);
    draw_text(_cx, 80, "SELECT MODE");

    var _bw = 200;
    var _bh = 60;
    var _gap = 40;
    var _total = (_bw * 2) + _gap;
    var _online_x = _cx - _total / 2;
    var _lan_x    = _cx + _gap / 2;
    var _by       = _cy - _bh / 2;

    // Online button
    draw_set_color(make_color_rgb(30, 60, 120));
    draw_rectangle(_online_x, _by, _online_x + _bw, _by + _bh, false);
    draw_set_color(c_aqua);
    draw_rectangle(_online_x, _by, _online_x + _bw, _by + _bh, true);
    draw_set_color(c_white);
    draw_text(_online_x + _bw / 2, _by + 12, "ONLINE");
    draw_set_color(c_ltgray);
    draw_text(_online_x + _bw / 2, _by + 34, "press O");

    // LAN button
    draw_set_color(make_color_rgb(30, 80, 40));
    draw_rectangle(_lan_x, _by, _lan_x + _bw, _by + _bh, false);
    draw_set_color(c_lime);
    draw_rectangle(_lan_x, _by, _lan_x + _bw, _by + _bh, true);
    draw_set_color(c_white);
    draw_text(_lan_x + _bw / 2, _by + 12, "LAN");
    draw_set_color(c_ltgray);
    draw_text(_lan_x + _bw / 2, _by + 34, "press L");

    exit;
}

// ════════════════════════════════════════════════════════════════════════════
//  SCREEN: LAN
// ════════════════════════════════════════════════════════════════════════════
if (current_screen == SCREEN_LAN) {

    draw_set_color(c_white);
    draw_text(_cx, 30, "LAN");
    draw_set_color(c_ltgray);
    draw_text(_cx, 60, status_msg);

    // Tab headers
    var _tab_w  = 160;
    var _tab_h  = 34;
    var _join_x = _cx - _tab_w - 4;
    var _host_x = _cx + 4;
    var _tab_y  = 96;

    // Join tab
    draw_set_color(lan_join_mode ? make_color_rgb(30, 60, 120) : make_color_rgb(20,20,20));
    draw_rectangle(_join_x, _tab_y, _join_x + _tab_w, _tab_y + _tab_h, false);
    draw_set_color(lan_join_mode ? c_aqua : c_dkgray);
    draw_rectangle(_join_x, _tab_y, _join_x + _tab_w, _tab_y + _tab_h, true);
    draw_set_color(lan_join_mode ? c_white : c_gray);
    draw_text(_join_x + _tab_w / 2, _tab_y + 8, "JOIN");

    // Host tab
    draw_set_color(!lan_join_mode ? make_color_rgb(60, 30, 10) : make_color_rgb(20,20,20));
    draw_rectangle(_host_x, _tab_y, _host_x + _tab_w, _tab_y + _tab_h, false);
    draw_set_color(!lan_join_mode ? c_orange : c_dkgray);
    draw_rectangle(_host_x, _tab_y, _host_x + _tab_w, _tab_y + _tab_h, true);
    draw_set_color(!lan_join_mode ? c_white : c_gray);
    draw_text(_host_x + _tab_w / 2, _tab_y + 8, "HOST");

    var _form_y  = _tab_y + _tab_h + 20;
    var _label_x = _cx - 180;
    var _field_x = _cx - 80;
    var _field_w = 300;
    var _field_h = 28;

    if (lan_join_mode) {
        // ── JOIN TAB CONTENT ──────────────────────────────────────────────
        draw_set_color(c_ltgray);
        draw_set_halign(fa_center);
        draw_text(_cx, _tab_y + _tab_h + 14, status_msg);

        // Build host list for display
        var _keys = [];
        var _k = ds_map_find_first(lan_hosts);
        while (!is_undefined(_k)) {
            array_push(_keys, _k);
            _k = ds_map_find_next(lan_hosts, _k);
        }
        var _host_count = array_length(_keys);

        if (_host_count == 0) {
            draw_set_color(c_gray);
            draw_text(_cx, _cy, "(No hosts found on this network)");
            draw_set_color(c_dkgray);
            draw_text(_cx, _cy + 28, "Make sure the host has started a LAN lobby");
        } else {
            // Column headers
            var _col_name    = 60;
            var _col_players = _gw - 140;
            var _row_top2    = _tab_y + _tab_h + 36;
            var _row_h2      = 28;

            draw_set_halign(fa_left);
            draw_set_color(c_yellow);
            draw_text(_col_name,    _row_top2, "HOST");
            draw_text(_col_players, _row_top2, "PLAYERS");
            draw_set_color(c_dkgray);
            draw_line(50, _row_top2 + 18, _gw - 50, _row_top2 + 18);

            for (var _i = 0; _i < _host_count; _i++) {
                var _ry    = _row_top2 + 24 + _i * _row_h2;
                var _e     = lan_hosts[? _keys[_i]];
                var _sel   = (_i == lan_selected);

                if (_sel) {
                    draw_set_color(make_color_rgb(35, 70, 130));
                    draw_rectangle(48, _ry - 3, _gw - 48, _ry + _row_h2 - 4, false);
                }

                draw_set_color(_sel ? c_white : c_silver);
                draw_set_halign(fa_left);
                var _dname = _e[? "name"];
                if (_e[? "has_pw"]) _dname = "[P] " + _dname;
                draw_text(_col_name, _ry, _dname);
                draw_text(_col_players, _ry,
                    string(_e[? "current"]) + " / " + string(_e[? "max"]));
            }
        }

        draw_set_halign(fa_center);
        draw_set_color(c_dkgray);
        draw_text(_cx, _gh - 36, "Up/Down select   ENTER join   TAB switch to host");

    } else {
        // ── HOST TAB CONTENT ──────────────────────────────────────────────
        draw_set_halign(fa_center);
        if (launching) {
            draw_set_color(c_yellow);
            draw_text(_cx, _cy - 10, "Starting server...");
            draw_set_color(c_dkgray);
            draw_text(_cx, _cy + 18, string_repeat(".", (current_time div 250) mod 4));
        } else {
            draw_set_color(c_lime);
            draw_text(_cx, _cy - 20, "Hosting");
            draw_set_color(c_ltgray);
            draw_text(_cx, _cy + 10, "Waiting for players to join...");
            draw_set_color(c_dkgray);
            draw_text(_cx, _cy + 36, "Players on your network will see");
            draw_text(_cx, _cy + 54, "your game in the JOIN tab automatically.");
        }
    }

    // Bottom hints
    draw_set_halign(fa_center);
    draw_set_color(c_dkgray);
    draw_text(_cx, _gh - 36, "TAB — switch between Join / Host   ESC — back");

    exit;
}

// ════════════════════════════════════════════════════════════════════════════
//  SCREEN: CREATE LOBBY (online)
// ════════════════════════════════════════════════════════════════════════════
if (current_screen == SCREEN_CREATE) {

    draw_set_color(c_white);
    draw_text(_cx, 30, "CREATE LOBBY  (ONLINE)");
    draw_set_color(c_ltgray);
    draw_text(_cx, 60, status_msg);

    var _form_y  = 120;
    var _label_x = _cx - 180;
    var _field_x = _cx - 80;
    var _field_w = 300;
    var _field_h = 28;
    var _row_gap = 50;

    // Name field
    var _nfoc = (create_focus == "name");
    draw_set_halign(fa_left);
    draw_set_color(c_ltgray);
    draw_text(_label_x, _form_y + 6, "Lobby Name");
    draw_set_color(_nfoc ? make_color_rgb(30,50,90) : make_color_rgb(20,20,30));
    draw_rectangle(_field_x, _form_y, _field_x + _field_w, _form_y + _field_h, false);
    draw_set_color(_nfoc ? c_aqua : c_dkgray);
    draw_rectangle(_field_x, _form_y, _field_x + _field_w, _form_y + _field_h, true);
    var _cur_n = (_nfoc && ((current_time div 500) mod 2 == 0)) ? "|" : "";
    draw_set_color(c_white);
    draw_text(_field_x + 6, _form_y + 6, create_name + _cur_n);
    _form_y += _row_gap;

    // Public/Private toggle
    draw_set_color(c_ltgray);
    draw_text(_label_x, _form_y + 6, "Visibility");
    var _pub_x  = _field_x;
    var _priv_x = _field_x + 120;
    var _btn_w  = 110;
    draw_set_color(!create_private ? make_color_rgb(40,120,60) : make_color_rgb(30,30,30));
    draw_rectangle(_pub_x,  _form_y, _pub_x  + _btn_w, _form_y + _field_h, false);
    draw_set_color(create_private  ? make_color_rgb(110,40,40) : make_color_rgb(30,30,30));
    draw_rectangle(_priv_x, _form_y, _priv_x + _btn_w, _form_y + _field_h, false);
    draw_set_color(!create_private ? c_lime : c_dkgray);
    draw_rectangle(_pub_x,  _form_y, _pub_x  + _btn_w, _form_y + _field_h, true);
    draw_set_color(create_private  ? c_red  : c_dkgray);
    draw_rectangle(_priv_x, _form_y, _priv_x + _btn_w, _form_y + _field_h, true);
    draw_set_halign(fa_center);
    draw_set_color(!create_private ? c_white : c_gray);
    draw_text(_pub_x  + _btn_w / 2, _form_y + 6, "PUBLIC");
    draw_set_color(create_private  ? c_white : c_gray);
    draw_text(_priv_x + _btn_w / 2, _form_y + 6, "PRIVATE");
    draw_set_color(c_dkgray);
    draw_set_halign(fa_left);
    draw_text(_priv_x + _btn_w + 10, _form_y + 6, "(P to toggle)");
    _form_y += _row_gap;

    // Password field
    if (create_private) {
        var _pfoc = (create_focus == "password");
        draw_set_color(c_ltgray);
        draw_text(_label_x, _form_y + 6, "Password");
        draw_set_color(_pfoc ? make_color_rgb(30,50,90) : make_color_rgb(20,20,30));
        draw_rectangle(_field_x, _form_y, _field_x + _field_w, _form_y + _field_h, false);
        draw_set_color(_pfoc ? c_aqua : c_dkgray);
        draw_rectangle(_field_x, _form_y, _field_x + _field_w, _form_y + _field_h, true);
        var _stars = string_repeat("*", string_length(create_pw));
        var _cur_p = (_pfoc && ((current_time div 500) mod 2 == 0)) ? "|" : "";
        draw_set_color(c_white);
        draw_text(_field_x + 6, _form_y + 6, _stars + _cur_p);
        _form_y += _row_gap;
    }

    draw_set_halign(fa_center);
    draw_set_color(c_ltgray);
    draw_text(_cx, _form_y + 10, "ENTER — Create Lobby");
    draw_set_color(c_dkgray);
    draw_text(_cx, _gh - 36, "ESC back   TAB switch fields   P toggle private");

    exit;
}

// ════════════════════════════════════════════════════════════════════════════
//  SCREEN: BROWSE (online)
// ════════════════════════════════════════════════════════════════════════════

draw_set_color(c_white);
draw_text(_cx, 30, "SERVER BROWSER  (ONLINE)");
draw_set_color(c_ltgray);
draw_text(_cx, 60, status_msg);

var _col_name    = 60;
var _col_status  = _gw - 260;
var _col_players = _gw - 120;
var _row_top     = 110;
var _row_h       = 28;

draw_set_halign(fa_left);
draw_set_color(c_yellow);
draw_text(_col_name,    _row_top, "NAME");
draw_text(_col_status,  _row_top, "STATUS");
draw_text(_col_players, _row_top, "PLAYERS");
draw_set_color(c_dkgray);
draw_line(50, _row_top + 20, _gw - 50, _row_top + 20);

var _count = ds_list_size(lobby_list);
if (_count == 0) {
    draw_set_halign(fa_center);
    draw_set_color(c_gray);
    draw_text(_cx, _gh / 2, "(No lobbies — press C to create one)");
} else {
    for (var _i = 0; _i < _count; _i++) {
        var _e      = ds_list_find_value(lobby_list, _i);
        var _ry     = _row_top + 26 + _i * _row_h;
        var _sel    = (_i == selected_index);
        var _active = (_e[? "is_active"] == 1);
        var _full   = (_e[? "current"] >= _e[? "max"]);

        if (_sel) {
            draw_set_color(make_color_rgb(35, 70, 130));
            draw_rectangle(48, _ry - 3, _gw - 48, _ry + _row_h - 4, false);
        }

        draw_set_color(_sel ? c_white : (_active || _full ? c_gray : c_silver));
        draw_set_halign(fa_left);

        var _name = _e[? "name"];
        if (_e[? "has_password"]) _name = "[P] " + _name;
        draw_text(_col_name,    _ry, _name);
        draw_text(_col_status,  _ry, _active ? "IN MATCH" : (_full ? "FULL" : "WAITING"));
        draw_text(_col_players, _ry, string(_e[? "current"]) + " / " + string(_e[? "max"]));
    }
}

draw_set_halign(fa_center);
draw_set_color(c_dkgray);
draw_text(_cx, _gh - 36,
    "Up/Down navigate   ENTER join   C create   R refresh   ESC back   [P] = password");

// Password overlay
if (pw_mode) {
    draw_set_color(c_black);
    draw_set_alpha(0.65);
    draw_rectangle(0, 0, _gw, _gh, false);
    draw_set_alpha(1);

    var _bx1 = _cx - 210; var _by1 = _gh / 2 - 75;
    var _bx2 = _cx + 210; var _by2 = _gh / 2 + 75;
    draw_set_color(make_color_rgb(18, 18, 36));
    draw_rectangle(_bx1, _by1, _bx2, _by2, false);
    draw_set_color(c_white);
    draw_rectangle(_bx1, _by1, _bx2, _by2, true);
    draw_text(_cx, _by1 + 14, "Password Required");
    var _stars = string_repeat("*", string_length(pw_input));
    var _cur   = (((current_time div 500) mod 2) == 0) ? "|" : "";
    draw_set_color(make_color_rgb(200, 230, 255));
    draw_text(_cx, _gh / 2 - 10, _stars + _cur);
    draw_set_color(c_dkgray);
    draw_text(_cx, _by2 - 22, "ENTER confirm   ESC cancel");
}
