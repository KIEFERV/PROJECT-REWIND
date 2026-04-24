/// @description Draw Debug Menu Elements
#macro NEWLINE _dy += 20

var _dy = 40

if(debug_menu = true){
	draw_text(50, _dy, "total velocity: " + string_format(velocity, 5, 3)); NEWLINE;
	draw_text(50, _dy, "move_speed:     " + string_format(move_speed, 5, 3)); NEWLINE;
	draw_text(50, _dy, "impulse_force:  " + string_format(point_distance(0, 0, impulse_force_x, impulse_force_y), 5, 3)); NEWLINE;
	draw_text(50, _dy, "constant_force: " + string_format(point_distance(0, 0, constant_force_x, constant_force_y), 5, 3)); NEWLINE;
}


if (show_GUI = true){
	draw_healthbar(10, 715, 450, 750, hitpoints, c_maroon, c_red, c_green, 0, true, true);
}

	
// Format as MM:SS
var minutes = floor(time_remaining / 60);
var seconds = time_remaining mod 60;
var timeStr = string(minutes) + ":" + (seconds < 10 ? "0" : "") + string(seconds);

// Draw centered at top of screen
draw_set_halign(fa_center);
draw_set_valign(fa_top);
draw_set_color(c_white);
//draw_set_font(fnt_timer);  // replace with your font, or remove this line to use default
draw_text(display_get_gui_width() / 2, 20, timeStr);
draw_set_halign(fa_left);
draw_set_valign(fa_top);