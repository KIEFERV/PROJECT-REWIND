///@description 

//get inputs
key_right = keyboard_check(ord("D"));
key_left = keyboard_check(ord("A"));
key_up = keyboard_check(ord("W"));
key_down = keyboard_check(ord("S"));
key_sprint = keyboard_check(vk_shift);

//get x and y speeds (base speed)
hor_speed = sign(key_right - key_left) * move_speed;
vert_speed = sign(key_down - key_up) * move_speed;

	//player collision
//horizontal (x-axis)
if place_meeting(x + hor_speed, y, oCollision){
	hor_speed = 0;
}
//vertical (y-axis)
if place_meeting(x, y + vert_speed, oCollision){
	vert_speed = 0;
}

//player states

//Sprinting
if (key_sprint){
	sprinting = true;
	sprint_speed = 1.5;
}else{
	sprinting = false;
	sprint_speed = 1.0;
}

	//movement multipliers

//Sprinting
player_hor_speed = hor_speed * sprint_speed;
player_vert_speed = vert_speed * sprint_speed;

//move the player
x += player_hor_speed;
y += player_vert_speed;


if (keyboard_check_released(ord("M"))){
	
	debug_menu = !debug_menu;
	
}


