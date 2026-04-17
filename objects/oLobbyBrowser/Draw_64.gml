/// Draw_64 (Draw GUI) — oLobbyBrowser

var _gw  = display_get_gui_width();
var _gh  = display_get_gui_height();
var _cx  = _gw / 2;

draw_set_font(-1);
draw_set_color(c_white);
draw_set_halign(fa_center);

// ── Title & status ────────────────────────────────────────────────────────────
draw_text(_cx, 30, "SERVER BROWSER");
draw_set_color(c_ltgray);
draw_text(_cx, 60, status_msg);

// ── Column layout ─────────────────────────────────────────────────────────────
var _col_name   = 60;
var _col_status = _gw - 340;
var _col_ip     = _gw - 240;
var _col_player = _gw - 100;
var _row_top    = 110;
var _row_h      = 26;

// Header
draw_set_halign(fa_left);
draw_set_color(c_yellow);
draw_text(_col_name,   _row_top, "NAME");
draw_text(_col_status, _row_top, "STATUS");
draw_text(_col_ip,     _row_top, "ADDRESS");
draw_text(_col_player, _row_top, "PLAYERS");

// Separator
draw_set_color(c_dkgray);
draw_line(50, _row_top + 18, _gw - 50, _row_top + 18);

// ── Lobby rows ────────────────────────────────────────────────────────────────
var _count = ds_list_size(lobby_list);
if (_count == 0) {
    draw_set_halign(fa_center);
    draw_set_color(c_gray);
    draw_text(_cx, _gh / 2, "(No lobbies found)");
} else {
    for (var _i = 0; _i < _count; _i++) {
        var _e    = ds_list_find_value(lobby_list, _i);
        var _ry   = _row_top + 24 + _i * _row_h;
        var _sel  = (_i == selected_index);

        // Highlight bar
        if (_sel) {
            draw_set_color(make_color_rgb(40, 80, 130));
            draw_rectangle(48, _ry - 3, _gw - 48, _ry + _row_h - 5, false);
        }

        // Row text colour
        var _active = _e[? "is_active"];
        if (_sel)         draw_set_color(c_white);
        else if (_active) draw_set_color(c_gray);   // dim active (in-match) lobbies
        else              draw_set_color(c_silver);

        draw_set_halign(fa_left);

        // Name  +  lock icon for password lobbies
        var _name = _e[? "name"];
        if (_e[? "has_password"]) _name = "[P] " + _name;
        draw_text(_col_name, _ry, _name);

        // Status
        draw_text(_col_status, _ry, _active ? "IN MATCH" : "WAITING");

        // IP:port
        draw_text(_col_ip, _ry,
            _e[? "host_ip"] + ":" + string(_e[? "host_port"]));

        // Player count
        draw_text(_col_player, _ry,
            string(_e[? "current"]) + "/" + string(_e[? "max"]));
    }
}

// ── Controls hint ─────────────────────────────────────────────────────────────
draw_set_halign(fa_center);
draw_set_color(c_dkgray);
draw_text(_cx, _gh - 40, "↑↓ navigate   ENTER join   R refresh   [P] = password required");

// ════════════════════════════════════════════════════════════════════════════
//  PASSWORD PROMPT OVERLAY
// ════════════════════════════════════════════════════════════════════════════
if (pw_mode) {
    // Dim background
    draw_set_color(make_color_rgb(0, 0, 0));
    draw_set_alpha(0.65);
    draw_rectangle(0, 0, _gw, _gh, false);
    draw_set_alpha(1);

    // Modal box
    var _bx1 = _cx - 200, _by1 = _gh / 2 - 70;
    var _bx2 = _cx + 200, _by2 = _gh / 2 + 70;
    draw_set_color(make_color_rgb(20, 20, 40));
    draw_rectangle(_bx1, _by1, _bx2, _by2, false);
    draw_set_color(c_white);
    draw_rectangle(_bx1, _by1, _bx2, _by2, true);

    draw_set_halign(fa_center);
    draw_set_color(c_white);
    draw_text(_cx, _by1 + 16, "Enter Password");

    // Password field  (mask with asterisks)
    var _stars = "";
    for (var _s = 0; _s < string_length(pw_input); _s++) _stars += "*";

    draw_set_color(make_color_rgb(200, 230, 255));
    draw_text(_cx, _gh / 2 - 8, _stars + (((current_time div 500) mod 2) == 0 ? "|" : ""));

    draw_set_color(c_dkgray);
    draw_text(_cx, _by2 - 24, "ENTER confirm   ESC cancel");
}
