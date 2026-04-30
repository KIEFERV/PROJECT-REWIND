/// Draw_64 (Draw GUI) — oLobby

var _gw = display_get_gui_width();
var _gh = display_get_gui_height();
var _cx = _gw / 2;
var _cy = _gh / 2;

draw_set_font(-1);
draw_set_halign(fa_center);
draw_set_valign(fa_top);

// ── Title ─────────────────────────────────────────────────────────────────
draw_set_color(c_white);
draw_text(_cx, 30, "LOBBY");

// ── Status ────────────────────────────────────────────────────────────────
draw_set_color(is_host ? c_lime : c_yellow);
draw_text(_cx, 58, status_msg);

// ── Player list panel ─────────────────────────────────────────────────────
var _panel_w = 340;
var _panel_x = _cx - _panel_w / 2;
var _panel_y = 100;
var _row_h   = 32;
var _max_rows = 8;
var _panel_h  = 24 + _max_rows * _row_h;

// Panel background
draw_set_color(make_color_rgb(15, 20, 35));
draw_rectangle(_panel_x, _panel_y, _panel_x + _panel_w, _panel_y + _panel_h, false);
draw_set_color(make_color_rgb(50, 80, 140));
draw_rectangle(_panel_x, _panel_y, _panel_x + _panel_w, _panel_y + _panel_h, true);

// Header
draw_set_halign(fa_left);
draw_set_color(c_yellow);
draw_text(_panel_x + 12, _panel_y + 6, "PLAYERS  (" + string(player_count) + ")");

// Player rows
var _ry = _panel_y + 30;
var _slot = 1;
var _max_players = 4;

for (var _slot = 1; _slot <= _max_players; _slot++) {
    var _name = ds_map_find_value(lobby_players, _slot);
    var _filled = !is_undefined(_name);

    // Row background
    if (_filled) {
        draw_set_color(_slot == my_pid
            ? make_color_rgb(30, 60, 120)   // highlight our own slot
            : make_color_rgb(20, 35, 55));
    } else {
        draw_set_color(make_color_rgb(12, 15, 22));
    }
    draw_rectangle(_panel_x + 6, _ry, _panel_x + _panel_w - 6, _ry + _row_h - 4, false);

    // Slot number
    draw_set_color(c_dkgray);
    draw_text(_panel_x + 18, _ry + 8, string(_slot));

    // Name
    draw_set_halign(fa_left);
    if (_filled) {
        draw_set_color(_slot == my_pid ? c_aqua : c_white);
        var _display = _name;
        if (_slot == 1) _display += "  [HOST]";
        if (_slot == my_pid) _display += "  (you)";
        draw_text(_panel_x + 36, _ry + 8, _display);
    } else {
        draw_set_color(make_color_rgb(50, 55, 65));
        draw_text(_panel_x + 36, _ry + 8, "Waiting...");
    }

    _ry += _row_h;
}

// ── Hint ─────────────────────────────────────────────────────────────────
draw_set_halign(fa_center);
draw_set_color(c_dkgray);
if (is_host) {
    draw_text(_cx, _gh - 36, "SPACE — start match   (need at least 2 players)");
} else {
    draw_text(_cx, _gh - 36, "Waiting for host to start the match...");
}
