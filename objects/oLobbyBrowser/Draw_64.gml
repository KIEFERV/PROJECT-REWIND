/// Draw_64 (Draw GUI) — oLobbyBrowser

var _gw = display_get_gui_width();
var _gh = display_get_gui_height();
var _cx = _gw / 2;
var _cy = _gh / 2;

draw_set_font(-1);
draw_set_halign(fa_center);
draw_set_valign(fa_top);

// ════════════════════════════════════════════════════════════════════════════
//  LAUNCH OVERLAY  (shown while server.exe is starting up)
// ════════════════════════════════════════════════════════════════════════════
if (launching) {
    draw_set_color(c_black);
    draw_set_alpha(0.80);
    draw_rectangle(0, 0, _gw, _gh, false);
    draw_set_alpha(1);
    draw_set_color(c_white);
    draw_text(_cx, _cy - 12, status_msg);
    // Animate dots using current_time so no step variables are needed
    var _dots = string_repeat(".", (current_time div 250) mod 4);
    draw_set_color(c_ltgray);
    draw_text(_cx, _cy + 14, _dots);
    exit;
}

// ════════════════════════════════════════════════════════════════════════════
//  SCREEN: CREATE LOBBY
// ════════════════════════════════════════════════════════════════════════════
if (current_screen == SCREEN_CREATE) {

    // Title
    draw_set_color(c_white);
    draw_text(_cx, 30, "CREATE LOBBY");

    // Status / hint
    draw_set_color(c_ltgray);
    draw_text(_cx, 60, status_msg);

    var _form_y   = 120;
    var _label_x  = _cx - 180;
    var _field_x  = _cx - 80;
    var _field_w  = 300;
    var _field_h  = 28;
    var _row_gap  = 50;

    // ── Lobby Name field ──────────────────────────────────────────────────
    var _name_focused = (create_focus == "name");
    draw_set_halign(fa_left);
    draw_set_color(c_ltgray);
    draw_text(_label_x, _form_y + 6, "Lobby Name");

    // Field background
    draw_set_color(_name_focused ? make_color_rgb(30, 50, 90) : make_color_rgb(20, 20, 30));
    draw_rectangle(_field_x, _form_y, _field_x + _field_w, _form_y + _field_h, false);
    draw_set_color(_name_focused ? c_aqua : c_dkgray);
    draw_rectangle(_field_x, _form_y, _field_x + _field_w, _form_y + _field_h, true);

    var _cursor_name = (_name_focused && ((current_time div 500) mod 2 == 0)) ? "|" : "";
    draw_set_color(c_white);
    draw_text(_field_x + 6, _form_y + 6, create_name + _cursor_name);

    _form_y += _row_gap;

    // ── Public / Private toggle ───────────────────────────────────────────
    draw_set_color(c_ltgray);
    draw_text(_label_x, _form_y + 6, "Visibility");

    // Public button
    var _pub_x  = _field_x;
    var _priv_x = _field_x + 120;
    var _btn_w  = 110;
    var _btn_h  = _field_h;

    draw_set_color(!create_private ? make_color_rgb(40, 120, 60) : make_color_rgb(30, 30, 30));
    draw_rectangle(_pub_x, _form_y, _pub_x + _btn_w, _form_y + _btn_h, false);
    draw_set_color(!create_private ? c_lime : c_dkgray);
    draw_rectangle(_pub_x, _form_y, _pub_x + _btn_w, _form_y + _btn_h, true);
    draw_set_color(!create_private ? c_white : c_gray);
    draw_set_halign(fa_center);
    draw_text(_pub_x + _btn_w / 2, _form_y + 6, "PUBLIC");

    draw_set_color(create_private ? make_color_rgb(110, 40, 40) : make_color_rgb(30, 30, 30));
    draw_rectangle(_priv_x, _form_y, _priv_x + _btn_w, _form_y + _btn_h, false);
    draw_set_color(create_private ? c_red : c_dkgray);
    draw_rectangle(_priv_x, _form_y, _priv_x + _btn_w, _form_y + _btn_h, true);
    draw_set_color(create_private ? c_white : c_gray);
    draw_text(_priv_x + _btn_w / 2, _form_y + 6, "PRIVATE");

    draw_set_halign(fa_left);
    draw_set_color(c_dkgray);
    draw_text(_priv_x + _btn_w + 10, _form_y + 6, "(P to toggle)");

    _form_y += _row_gap;

    // ── Password field (only shown when private) ───────────────────────────
    if (create_private) {
        var _pw_focused = (create_focus == "password");
        draw_set_color(c_ltgray);
        draw_text(_label_x, _form_y + 6, "Password");

        draw_set_color(_pw_focused ? make_color_rgb(30, 50, 90) : make_color_rgb(20, 20, 30));
        draw_rectangle(_field_x, _form_y, _field_x + _field_w, _form_y + _field_h, false);
        draw_set_color(_pw_focused ? c_aqua : c_dkgray);
        draw_rectangle(_field_x, _form_y, _field_x + _field_w, _form_y + _field_h, true);

        // Mask password with asterisks
        var _stars = "";
        for (var _s = 0; _s < string_length(create_pw); _s++) _stars += "*";
        var _cursor_pw = (_pw_focused && ((current_time div 500) mod 2 == 0)) ? "|" : "";
        draw_set_color(c_white);
        draw_text(_field_x + 6, _form_y + 6, _stars + _cursor_pw);

        _form_y += _row_gap;

        // TAB hint
        draw_set_color(c_dkgray);
        draw_set_halign(fa_left);
        draw_text(_label_x, _form_y - 14, "TAB to switch fields");
    }

    // ── Create / Back buttons ──────────────────────────────────────────────
    _form_y += 10;
    draw_set_halign(fa_center);

    draw_set_color(make_color_rgb(40, 100, 40));
    draw_rectangle(_cx - 100, _form_y, _cx + 100, _form_y + 32, false);
    draw_set_color(c_lime);
    draw_rectangle(_cx - 100, _form_y, _cx + 100, _form_y + 32, true);
    draw_set_color(c_white);
    draw_text(_cx, _form_y + 7, "ENTER — Create Lobby");

    draw_set_color(c_dkgray);
    draw_text(_cx, _form_y + 44, "ESC — back to browser");

    exit;
}

// ════════════════════════════════════════════════════════════════════════════
//  SCREEN: BROWSE
// ════════════════════════════════════════════════════════════════════════════

// Title
draw_set_color(c_white);
draw_text(_cx, 30, "SERVER BROWSER");

// Status bar
draw_set_color(c_ltgray);
draw_text(_cx, 60, status_msg);

// ── Column definitions (NO address column) ───────────────────────────────
var _col_name    = 60;
var _col_status  = _gw - 260;
var _col_players = _gw - 120;
var _row_top     = 110;
var _row_h       = 28;

// Header
draw_set_halign(fa_left);
draw_set_color(c_yellow);
draw_text(_col_name,    _row_top, "NAME");
draw_text(_col_status,  _row_top, "STATUS");
draw_text(_col_players, _row_top, "PLAYERS");

draw_set_color(c_dkgray);
draw_line(50, _row_top + 20, _gw - 50, _row_top + 20);

// ── Lobby rows ────────────────────────────────────────────────────────────
var _count = ds_list_size(lobby_list);
if (_count == 0) {
    draw_set_halign(fa_center);
    draw_set_color(c_gray);
    draw_text(_cx, _cy, "(No lobbies found — press C to create one)");
} else {
    for (var _i = 0; _i < _count; _i++) {
        var _e      = ds_list_find_value(lobby_list, _i);
        var _ry     = _row_top + 26 + _i * _row_h;
        var _sel    = (_i == selected_index);
        var _active = (_e[? "is_active"] == 1);
        var _full   = (_e[? "current"] >= _e[? "max"]);

        // Selection highlight
        if (_sel) {
            draw_set_color(make_color_rgb(35, 70, 130));
            draw_rectangle(48, _ry - 3, _gw - 48, _ry + _row_h - 4, false);
        }

        // Text colour — dim lobbies that are in-match or full
        if      (_sel)                          draw_set_color(c_white);
        else if (_active || _full)              draw_set_color(c_gray);
        else                                    draw_set_color(c_silver);

        draw_set_halign(fa_left);

        // Name — prepend lock symbol for private lobbies
        var _name = _e[? "name"];
        if (_e[? "has_password"]) _name = "[P] " + _name;
        draw_text(_col_name, _ry, _name);

        // Status
        var _status_str = _active ? "IN MATCH" : (_full ? "FULL" : "WAITING");
        draw_text(_col_status, _ry, _status_str);

        // Player count
        draw_text(_col_players, _ry,
            string(_e[? "current"]) + " / " + string(_e[? "max"]));
    }
}

// ── Bottom hint bar ───────────────────────────────────────────────────────
draw_set_halign(fa_center);
draw_set_color(c_dkgray);
draw_text(_cx, _gh - 36,
    "↑↓ navigate   ENTER join   C create lobby   R refresh   [P] = password");

// ════════════════════════════════════════════════════════════════════════════
//  BROWSE — PASSWORD OVERLAY  (joining a private lobby)
// ════════════════════════════════════════════════════════════════════════════
if (pw_mode) {
    // Semi-transparent backdrop
    draw_set_color(c_black);
    draw_set_alpha(0.65);
    draw_rectangle(0, 0, _gw, _gh, false);
    draw_set_alpha(1);

    var _bx1 = _cx - 210, _by1 = _cy - 75;
    var _bx2 = _cx + 210, _by2 = _cy + 75;

    draw_set_color(make_color_rgb(18, 18, 36));
    draw_rectangle(_bx1, _by1, _bx2, _by2, false);
    draw_set_color(c_white);
    draw_rectangle(_bx1, _by1, _bx2, _by2, true);

    draw_set_halign(fa_center);
    draw_set_color(c_white);
    draw_text(_cx, _by1 + 14, "Password Required");

    // Asterisk-masked input + blinking cursor
    var _stars = string_repeat("*", string_length(pw_input));
    var _cur   = (((current_time div 500) mod 2) == 0) ? "|" : "";
    draw_set_color(make_color_rgb(200, 230, 255));
    draw_text(_cx, _cy - 10, _stars + _cur);

    draw_set_color(c_dkgray);
    draw_text(_cx, _by2 - 22, "ENTER confirm   ESC cancel");
}
