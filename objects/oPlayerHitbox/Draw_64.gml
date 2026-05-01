/// Draw_64 (Draw GUI) — oPlayerHitbox

var _gw = display_get_gui_width();
var _gh = display_get_gui_height();
var _cx = _gw / 2;

// ── WINNER SCREEN ─────────────────────────────────────────────────────────
if (global.match_phase == "winner") {
    draw_set_color(c_black);
    draw_set_alpha(0.80);
    draw_rectangle(0, 0, _gw, _gh, false);
    draw_set_alpha(1);
    draw_set_halign(fa_center);
    draw_set_color(c_yellow);
    draw_text(_cx, _gh/2 - 50, "MATCH OVER");
    draw_set_color(c_white);
    draw_text(_cx, _gh/2, global.match_winner_name + " wins!");
    draw_set_color(c_dkgray);
    draw_text(_cx, _gh/2 + 40, "Returning to menu...");
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    exit;
}

// ── COUNTDOWN ─────────────────────────────────────────────────────────────
if (global.match_phase == "countdown") {
    draw_set_halign(fa_center);
    draw_set_color(c_white);
    if (global.countdown_value > 0) {
        draw_text(_cx, _gh/2 - 30, string(global.countdown_value));
    } else {
        draw_set_color(c_lime);
        draw_text(_cx, _gh/2 - 30, "GO!");
    }
    draw_set_halign(fa_left);
}

// ── DEAD OVERLAY ──────────────────────────────────────────────────────────
if (!global.player_alive && global.match_phase == "playing") {
    draw_set_color(c_red);
    draw_set_alpha(0.45);
    draw_rectangle(0, 0, _gw, _gh, false);
    draw_set_alpha(1);
    draw_set_halign(fa_center);
    draw_set_color(c_white);
    draw_text(_cx, _gh/2, "ELIMINATED");
    draw_set_color(c_dkgray);
    draw_text(_cx, _gh/2 + 30, "Waiting for next round...");
    draw_set_halign(fa_left);
}

// ── ROUND SCORES ──────────────────────────────────────────────────────────
draw_set_halign(fa_center);
draw_set_color(c_white);
draw_text(_cx, 52, "Round " + string(global.round_number));
var _sx = _cx - 60;
for (var _pi = 1; _pi <= 4; _pi++) {
    if (global.scores[_pi] > 0 || _pi <= 2) {
        draw_set_color(_pi == my_pid ? c_yellow : c_ltgray);
        draw_text(_sx, 72, "P" + string(_pi) + ": " + string(global.scores[_pi]));
        _sx += 70;
    }
}
draw_set_halign(fa_left);

// ════════════════════════════════════════════════════════════════════════════
//  ORIGINAL oPlayerHitbox HUD BELOW
// ════════════════════════════════════════════════════════════════════════════
#macro NEWLINE _dy += 20

var _dy = 40

if(debug_menu = true){
	draw_set_font(-1)
	draw_text(50, _dy, "total velocity: " + string_format(velocity, 5, 3)); NEWLINE;
	draw_text(50, _dy, "move_speed:     " + string_format(move_speed, 5, 3)); NEWLINE;
	draw_text(50, _dy, "impulse_force:  " + string_format(point_distance(0, 0, impulse_force_x, impulse_force_y), 5, 3)); NEWLINE;
	draw_text(50, _dy, "constant_force: " + string_format(point_distance(0, 0, constant_force_x, constant_force_y), 5, 3)); NEWLINE;
}

if (show_GUI = true){
	draw_healthbar(10, 700, 450, 750, (hitpoints/max_hp)* 100, c_maroon, c_red, c_green, 0, true, true);
}

// ════════════════════════════════════════════════════════════════════════════
// REWIND ABILITY BAR
// ════════════════════════════════════════════════════════════════════════════

if (show_GUI = true){ //this is the rewind ability bar, probably a placeholder. cd is 6 secs.

var p = 1 - (time_cd / time_cd_max);
p = clamp(p, 0, 1); // Ensure within bounds

var bar_x = 130;
var bar_y = 670;
var bar_width = 200;
var bar_height = 20;

// Draw background
draw_set_color(c_gray);
draw_rectangle(bar_x, bar_y, bar_x + bar_width, bar_y + bar_height, false);

// Draw progress (teal, fills from left)
draw_set_color(#00FFE0);
draw_rectangle(bar_x, bar_y, bar_x + (bar_width * p), bar_y + bar_height, false);
draw_set_color(c_black);
draw_set_font(RewindBold);
draw_text(bar_x + (bar_width/4), bar_y-1, "R  E  W  I  N  D");
draw_set_color(#00FFE0);
draw_set_font(RewindFancy);
draw_text(bar_x + (bar_width/4), bar_y-bar_height, time_phase);
draw_set_color(c_white); // Reset color	
draw_set_font(-1); //Reset font
}

// ════════════════════════════════════════════════════════════════════════════
// TIMER
// ════════════════════════════════════════════════════════════════════════════

// Format as MM:SS
var minutes = floor(time_remaining / 60);
var seconds = time_remaining mod 60;
var timeStr = string(minutes) + ":" + (seconds < 10 ? "0" : "") + string(seconds);

draw_set_halign(fa_center);
draw_set_valign(fa_top);
draw_set_color(c_white);
draw_text(display_get_gui_width() / 2, 20, timeStr);
draw_set_halign(fa_left);
draw_set_valign(fa_top);

// ── Ammo HUD — bottom right ───────────────────────────────────────────────────
if (show_GUI = true) {
    var _gui_w  = display_get_gui_width();
    var _gui_h  = display_get_gui_height();
    var _margin = 20;
    var _line_h = 20;

    draw_set_halign(fa_right);
    draw_set_valign(fa_bottom);

    if (weapon_type == "melee") {
        draw_set_color(c_yellow);
        draw_text(_gui_w - _margin, _gui_h - _margin, "KNIFE");
    } else {
        var _slot_label = (active_slot == 1) ? "[1] " : "[2] ";
        var _wlabel = string_upper(_slot_label
            + ((active_slot == 1) ? primary_name : secondary_name));
        draw_set_color(make_color_rgb(180, 210, 255));
        draw_text(_gui_w - _margin, _gui_h - _margin - _line_h * 2, _wlabel);

        if (ammo_in_mag == 0)
            draw_set_color(c_red);
        else if (ammo_in_mag <= mag_size * 0.25)
            draw_set_color(make_color_rgb(255, 165, 0));
        else
            draw_set_color(c_white);

        draw_text(_gui_w - _margin, _gui_h - _margin - _line_h,
            string(ammo_in_mag) + "  /  " + string(ammo_reserve));

        if (reloading) {
            draw_set_color(make_color_rgb(255, 200, 50));
            draw_text(_gui_w - _margin, _gui_h - _margin, "RELOADING...");
        }
    }

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(c_white);
}
