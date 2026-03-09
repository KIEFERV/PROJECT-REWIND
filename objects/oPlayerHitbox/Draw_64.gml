/// @description Draw Debiug Menu Elements
#macro NEWLINE _dy += 20

var _dy = 40

if(debug_menu = true){
	draw_text(50, _dy, "total velocity: " + string_format(velocity, 5, 3)); NEWLINE;
	draw_text(50, _dy, "move_speed:     " + string_format(move_speed, 5, 3)); NEWLINE;
	draw_text(50, _dy, "impulse_force:  " + string_format(point_distance(0, 0, impulse_force_x, impulse_force_y), 5, 3)); NEWLINE;
	draw_text(50, _dy, "constant_force: " + string_format(point_distance(0, 0, constant_force_x, constant_force_y), 5, 3)); NEWLINE;
}




	
