/// @description Draw Debiug Menu Elements
/*
if(debug_menu = true){
	draw_text(50, 600, "player_hor_speed");
	draw_text(215, 600, player_hor_speed); //players horizontal speed
	draw_text(50, 615, "player_vert_speed");
	draw_text(215, 615, player_vert_speed); //players vertical speed
}
*/

#macro NEWLINE _dy += 20

var _dy = 40

draw_text(40, _dy, "total velocity: " + string_format(velocity, 5, 3)); NEWLINE;
draw_text(40, _dy, "move_speed:     " + string_format(move_speed, 5, 3)); NEWLINE;
draw_text(40, _dy, "impulse_force:  " + string_format(point_distance(0, 0, impulse_force_x, impulse_force_y), 5, 3)); NEWLINE;
draw_text(40, _dy, "constant_force: " + string_format(point_distance(0, 0, constant_force_x, constant_force_y), 5, 3)); NEWLINE;	
