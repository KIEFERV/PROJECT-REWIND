///@description Player Logic

//get inputs
key_right = keyboard_check(ord("D"));
key_left = keyboard_check(ord("A"));
key_up = keyboard_check(ord("W"));
key_down = keyboard_check(ord("S"));
key_sprint = keyboard_check(vk_shift);

if (keyboard_check_released(ord("M"))){debug_menu = !debug_menu;}

//Base Speed
var base_hor = sign(key_right - key_left) * move_speed;
var base_vert = sign(key_down - key_up) * move_speed;


	//player states
//Sprinting
var sprint_speed;
if (key_sprint){
	sprinting = true;
	sprint_speed = 1.5;
}else{
	sprinting = false;
	sprint_speed = 1.0;
}

	//movement multipliers
//Sprinting
player_hor_speed = base_hor * sprint_speed;
player_vert_speed = base_vert * sprint_speed;


//player collision after speed multipliers
//horizontal (x-axis)
if place_meeting(x + player_hor_speed, y, oCollisionBox){
	player_hor_speed = 0; //this is not affecting sprint
}
//vertical (y-axis)
if place_meeting(x, y + player_vert_speed, oCollisionBox){
	player_vert_speed = 0; //this is not affecting sprint
}

//move the player
x += player_hor_speed;
y += player_vert_speed;

//set the audio listener position
audio_listener_position(x, y, 0);

//detect distance from emitter
var dist = point_distance(x, y, oAudioEmitter.x, oAudioEmitter.y);
