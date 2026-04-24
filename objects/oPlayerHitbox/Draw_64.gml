/// @description Draw Debug Menu Elements
#macro NEWLINE _dy += 20

var _dy = 40

if(debug_menu = true){
	draw_text(50, _dy, "total velocity: " + string_format(velocity, 5, 3)); NEWLINE;
	draw_text(50, _dy, "move_speed:     " + string_format(move_speed, 5, 3)); NEWLINE;
	draw_text(50, _dy, "impulse_force:  " + string_format(point_distance(0, 0, impulse_force_x, impulse_force_y), 5, 3)); NEWLINE;
	draw_text(50, _dy, "constant_force: " + string_format(point_distance(0, 0, constant_force_x, constant_force_y), 5, 3)); NEWLINE;
}


	
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

// ── Ammo HUD — bottom right 
var _gui_w = display_get_gui_width();
var _gui_h = display_get_gui_height();
var _margin = 20;

draw_set_halign(fa_right);
draw_set_valign(fa_bottom);

if (weapon_type == "melee") {

    draw_set_color(c_yellow);
    draw_text(_gui_w - _margin, _gui_h - _margin, "KNIFE");
} else {

    var _line_h = 20;

    // Weapon name (topmost)
    var _slot_label = (active_slot == 1) ? "[1] " : "[2] ";
    var _wlabel = string_upper(_slot_label
        + ((active_slot == 1) ? primary_name : secondary_name));
    draw_set_color(make_color_rgb(180, 210, 255));
    draw_text(_gui_w - _margin, _gui_h - _margin - _line_h * 2, _wlabel);

    // Ammo count
    if (ammo_in_mag == 0)
        draw_set_color(c_red);
    else if (ammo_in_mag <= mag_size * 0.25)
        draw_set_color(make_color_rgb(255, 165, 0));
    else
        draw_set_color(c_white);

    var _ammo_str = string(ammo_in_mag) + "  /  " + string(ammo_reserve);
    draw_text(_gui_w - _margin, _gui_h - _margin - _line_h, _ammo_str);

    // Reload indicator 
    if (reloading) {
        draw_set_color(make_color_rgb(255, 200, 50));
        draw_text(_gui_w - _margin, _gui_h - _margin, "RELOADING...");
    }
}

draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_color(c_white);
