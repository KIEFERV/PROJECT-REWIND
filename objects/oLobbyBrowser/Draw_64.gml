/// Draw_64 (Draw GUI) — oLobbyBrowser

draw_set_font(-1);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_color(c_white);
draw_set_alpha(1);

var _gw = display_get_gui_width();
var _gh = display_get_gui_height();
var _cx = _gw / 2;
var _cy = _gh / 2;
var _mx = device_mouse_x_to_gui(0);
var _my = device_mouse_y_to_gui(0);

// ── LAUNCH OVERLAY ────────────────────────────────────────────────────────
if (launching) {
    draw_set_color(c_black);
    draw_set_alpha(0.80);
    draw_rectangle(0, 0, _gw, _gh, false);
    draw_set_alpha(1);
    draw_set_halign(fa_center);
    draw_set_color(c_white);
    draw_text(_cx, _cy - 12, status_msg);
    draw_set_color(c_ltgray);
    draw_text(_cx, _cy + 14, string_repeat(".", (current_time div 250) mod 4));
    draw_set_halign(fa_left);
    exit;
}

// ════════════════════════════════════════════════════════════════════════════
//  SCREEN: CREATE LOBBY
// ════════════════════════════════════════════════════════════════════════════
if (current_screen == SCREEN_CREATE) {

    // Panel
    var _pw  = 500; var _ph = 340;
    var _px  = _cx - _pw / 2;
    var _py  = _cy - _ph / 2;
    draw_set_alpha(0.92);
    draw_set_color(make_color_rgb(14, 16, 26));
    draw_rectangle(_px, _py, _px + _pw, _py + _ph, false);
    draw_set_alpha(1);
    draw_set_color(make_color_rgb(90, 110, 185));
    draw_rectangle(_px, _py, _px + _pw, _py + _ph, true);

    draw_set_halign(fa_center);
    draw_set_color(c_white);
    draw_text(_cx, _py + 18, "CREATE LOBBY");
    draw_set_color(make_color_rgb(180, 190, 220));
    draw_text(_cx, _py + 44, status_msg);
    draw_set_halign(fa_left);

    var _lx  = _px + 30;
    var _fx  = _px + 150;
    var _fw  = _pw - 180;
    var _fh  = 30;
    var _fy  = _py + 90;
    var _gap = 54;

    // ── Lobby Name field ──────────────────────────────────────────────────
    var _nfoc = (create_focus == "name");
    var _nhov = point_in_rectangle(_mx, _my, _fx, _fy, _fx + _fw, _fy + _fh);
    draw_set_color(c_ltgray);
    draw_text(_lx, _fy + 7, "Lobby Name");
    draw_set_color(_nfoc ? make_color_rgb(25,45,85) : (_nhov ? make_color_rgb(20,30,55) : make_color_rgb(16,18,28)));
    draw_rectangle(_fx, _fy, _fx + _fw, _fy + _fh, false);
    draw_set_color(_nfoc ? c_aqua : (_nhov ? c_ltgray : c_dkgray));
    draw_rectangle(_fx, _fy, _fx + _fw, _fy + _fh, true);
    var _cur_n = (_nfoc && ((current_time div 500) mod 2 == 0)) ? "|" : "";
    draw_set_color(c_white);
    draw_text(_fx + 8, _fy + 7, create_name + _cur_n);
    _fy += _gap;

    // ── Visibility toggle — clickable buttons ─────────────────────────────
    draw_set_color(c_ltgray);
    draw_text(_lx, _fy + 7, "Visibility");
    var _bw = 130;
    var _pub_x  = _fx;
    var _priv_x = _fx + _bw + 10;
    var _pub_hov  = point_in_rectangle(_mx, _my, _pub_x,  _fy, _pub_x  + _bw, _fy + _fh);
    var _priv_hov = point_in_rectangle(_mx, _my, _priv_x, _fy, _priv_x + _bw, _fy + _fh);

    // Public button
    draw_set_color(!create_private ? make_color_rgb(30,100,50) : (_pub_hov ? make_color_rgb(25,50,35) : make_color_rgb(20,28,22)));
    draw_rectangle(_pub_x, _fy, _pub_x + _bw, _fy + _fh, false);
    draw_set_color(!create_private ? c_lime : (_pub_hov ? c_ltgray : c_dkgray));
    draw_rectangle(_pub_x, _fy, _pub_x + _bw, _fy + _fh, true);
    draw_set_halign(fa_center);
    draw_set_color(!create_private ? c_white : c_gray);
    draw_text(_pub_x + _bw / 2, _fy + 7, "🌐  PUBLIC");

    // Private button
    draw_set_color(create_private ? make_color_rgb(100,30,30) : (_priv_hov ? make_color_rgb(55,25,25) : make_color_rgb(28,20,20)));
    draw_rectangle(_priv_x, _fy, _priv_x + _bw, _fy + _fh, false);
    draw_set_color(create_private ? c_red : (_priv_hov ? c_ltgray : c_dkgray));
    draw_rectangle(_priv_x, _fy, _priv_x + _bw, _fy + _fh, true);
    draw_set_color(create_private ? c_white : c_gray);
    draw_text(_priv_x + _bw / 2, _fy + 7, "🔒  PRIVATE");
    draw_set_halign(fa_left);
    _fy += _gap;

    // ── Password field (only when private) ───────────────────────────────
    if (create_private) {
        var _pfoc = (create_focus == "password");
        var _phov = point_in_rectangle(_mx, _my, _fx, _fy, _fx + _fw, _fy + _fh);
        draw_set_color(c_ltgray);
        draw_text(_lx, _fy + 7, "Password");
        draw_set_color(_pfoc ? make_color_rgb(25,45,85) : (_phov ? make_color_rgb(20,30,55) : make_color_rgb(16,18,28)));
        draw_rectangle(_fx, _fy, _fx + _fw, _fy + _fh, false);
        draw_set_color(_pfoc ? c_aqua : (_phov ? c_ltgray : c_dkgray));
        draw_rectangle(_fx, _fy, _fx + _fw, _fy + _fh, true);
        var _stars = string_repeat("*", string_length(create_pw));
        var _cur_p = (_pfoc && ((current_time div 500) mod 2 == 0)) ? "|" : "";
        draw_set_color(c_white);
        draw_text(_fx + 8, _fy + 7, _stars + _cur_p);
        _fy += _gap;
    }

    // ── Create button ─────────────────────────────────────────────────────
    var _cbw = 180; var _cbh = 36;
    var _cbx = _cx - _cbw / 2; var _cby = _py + _ph - 55;
    var _cbhov = point_in_rectangle(_mx, _my, _cbx, _cby, _cbx + _cbw, _cby + _cbh);
    draw_set_color(_cbhov ? make_color_rgb(60,90,180) : make_color_rgb(40,60,130));
    draw_rectangle(_cbx, _cby, _cbx + _cbw, _cby + _cbh, false);
    draw_set_color(_cbhov ? c_white : make_color_rgb(190,210,255));
    draw_rectangle(_cbx, _cby, _cbx + _cbw, _cby + _cbh, true);
    draw_set_halign(fa_center);
    draw_set_color(c_white);
    draw_text(_cbx + _cbw / 2, _cby + 9, "Create Lobby");

    // Back link
    draw_set_color(c_dkgray);
    draw_text(_cx, _py + _ph - 18, "ESC — back to browser");
    draw_set_halign(fa_left);

    exit;
}

// ════════════════════════════════════════════════════════════════════════════
//  SCREEN: BROWSE
// ════════════════════════════════════════════════════════════════════════════

draw_set_halign(fa_center);
draw_set_color(c_white);
draw_text(_cx, 24, "SERVER BROWSER");
draw_set_color(c_ltgray);
draw_text(_cx, 52, status_msg);
draw_set_halign(fa_left);

// Buttons row
var _btn_y  = _gh - 56;
var _btn_h  = 32;
var _btn_c  = 120; // Create button x
var _btn_r  = 260; // Refresh button x
var _btn_bk = _gw - 140; // Back button x
var _btn_bw = 110;

var _hov_c  = point_in_rectangle(_mx, _my, _btn_c,  _btn_y, _btn_c  + _btn_bw, _btn_y + _btn_h);
var _hov_r  = point_in_rectangle(_mx, _my, _btn_r,  _btn_y, _btn_r  + _btn_bw, _btn_y + _btn_h);
var _hov_bk = point_in_rectangle(_mx, _my, _btn_bk, _btn_y, _btn_bk + _btn_bw, _btn_y + _btn_h);

// Draw bottom buttons
var _btns = [
    { x: _btn_c,  label: "＋ Create",  hov: _hov_c  },
    { x: _btn_r,  label: "↻ Refresh",  hov: _hov_r  },
    { x: _btn_bk, label: "← Back",     hov: _hov_bk }
];
for (var _b = 0; _b < array_length(_btns); _b++) {
    var _bt = _btns[_b];
    draw_set_color(_bt.hov ? make_color_rgb(60,80,160) : make_color_rgb(30,35,55));
    draw_rectangle(_bt.x, _btn_y, _bt.x + _btn_bw, _btn_y + _btn_h, false);
    draw_set_color(_bt.hov ? c_white : make_color_rgb(160,180,220));
    draw_rectangle(_bt.x, _btn_y, _bt.x + _btn_bw, _btn_y + _btn_h, true);
    draw_set_halign(fa_center);
    draw_set_color(c_white);
    draw_text(_bt.x + _btn_bw / 2, _btn_y + 8, _bt.label);
}
draw_set_halign(fa_left);

// Lobby list
var _col_name    = 60;
var _col_status  = _gw - 260;
var _col_players = _gw - 120;
var _row_top     = 90;
var _row_h       = 32;

draw_set_color(c_yellow);
draw_text(_col_name,    _row_top, "NAME");
draw_text(_col_status,  _row_top, "STATUS");
draw_text(_col_players, _row_top, "PLAYERS");
draw_set_color(c_dkgray);
draw_line(48, _row_top + 22, _gw - 48, _row_top + 22);

var _count = ds_list_size(lobby_list);
if (_count == 0) {
    draw_set_halign(fa_center);
    draw_set_color(c_gray);
    draw_text(_cx, _gh / 2 - 30, "(No lobbies found)");
    draw_set_color(c_dkgray);
    draw_text(_cx, _gh / 2, "Click ＋ Create to host a lobby");
    draw_set_halign(fa_left);
} else {
    for (var _i = 0; _i < _count; _i++) {
        var _e    = ds_list_find_value(lobby_list, _i);
        var _ry   = _row_top + 28 + _i * _row_h;
        var _sel  = (_i == selected_index);
        var _hov  = !join_pending && !pw_mode &&
                    point_in_rectangle(_mx, _my, 48, _ry - 3, _gw - 48, _ry + _row_h - 4);
        var _full = (_e[? "current"] >= _e[? "max"]);

        if (_sel || _hov) {
            draw_set_color(_hov && !_sel ? make_color_rgb(25,50,90) : make_color_rgb(35,70,130));
            draw_rectangle(48, _ry - 3, _gw - 48, _ry + _row_h - 4, false);
        }

        draw_set_color(_sel ? c_white : (_full ? c_gray : c_silver));
        var _name = _e[? "name"];
        if (_e[? "has_password"]) _name = "🔒 " + _name;
        draw_text(_col_name,    _ry, _name);
        draw_text(_col_status,  _ry, _full ? "FULL" : "WAITING");
        draw_text(_col_players, _ry, string(_e[? "current"]) + " / " + string(_e[? "max"]));

        // Join button on hover
        if (_hov && !_full) {
            var _jbx = _gw - 155; var _jby = _ry - 1; var _jbw = 60; var _jbh = 22;
            draw_set_color(make_color_rgb(40,120,60));
            draw_rectangle(_jbx, _jby, _jbx + _jbw, _jby + _jbh, false);
            draw_set_color(c_lime);
            draw_rectangle(_jbx, _jby, _jbx + _jbw, _jby + _jbh, true);
            draw_set_halign(fa_center);
            draw_set_color(c_white);
            draw_text(_jbx + _jbw / 2, _jby + 4, "JOIN");
            draw_set_halign(fa_left);
        }
    }
}

// Password overlay
if (pw_mode) {
    draw_set_color(c_black);
    draw_set_alpha(0.65);
    draw_rectangle(0, 0, _gw, _gh, false);
    draw_set_alpha(1);
    var _bx1 = _cx - 210; var _by1 = _cy - 75;
    var _bx2 = _cx + 210; var _by2 = _cy + 75;
    draw_set_color(make_color_rgb(18,18,36));
    draw_rectangle(_bx1, _by1, _bx2, _by2, false);
    draw_set_color(c_white);
    draw_rectangle(_bx1, _by1, _bx2, _by2, true);
    draw_set_halign(fa_center);
    draw_set_color(c_white);
    draw_text(_cx, _by1 + 16, "🔒  Password Required");
    var _stars = string_repeat("*", string_length(pw_input));
    var _cur   = (((current_time div 500) mod 2) == 0) ? "|" : "";
    draw_set_color(make_color_rgb(200,230,255));
    draw_text(_cx, _cy - 8, _stars + _cur);
    // Confirm button
    var _cfx = _cx - 80; var _cfy = _by2 - 46; var _cfw = 70; var _cfh = 28;
    var _cfhov = point_in_rectangle(_mx, _my, _cfx, _cfy, _cfx + _cfw, _cfy + _cfh);
    draw_set_color(_cfhov ? make_color_rgb(40,120,60) : make_color_rgb(25,70,35));
    draw_rectangle(_cfx, _cfy, _cfx + _cfw, _cfy + _cfh, false);
    draw_set_color(c_lime);
    draw_rectangle(_cfx, _cfy, _cfx + _cfw, _cfy + _cfh, true);
    draw_set_color(c_white);
    draw_text(_cfx + _cfw / 2, _cfy + 6, "Join");
    // Cancel button
    var _ccx = _cx + 10; var _ccy = _cfy;
    var _cchov = point_in_rectangle(_mx, _my, _ccx, _ccy, _ccx + _cfw, _ccy + _cfh);
    draw_set_color(_cchov ? make_color_rgb(120,35,35) : make_color_rgb(70,20,20));
    draw_rectangle(_ccx, _ccy, _ccx + _cfw, _ccy + _cfh, false);
    draw_set_color(c_red);
    draw_rectangle(_ccx, _ccy, _ccx + _cfw, _ccy + _cfh, true);
    draw_set_color(c_white);
    draw_text(_ccx + _cfw / 2, _ccy + 6, "Cancel");
    draw_set_color(c_dkgray);
    draw_text(_cx, _by2 - 14, "ENTER confirm   ESC cancel");
    draw_set_halign(fa_left);
}
