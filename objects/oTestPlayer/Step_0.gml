event_inherited();



if (keyboard_check_pressed(ord("Z")) && time_phase = "present") { //Rewind phase logic
	
	if (!rewind_active) {
	plr_travel_start();
	}

} else {

	return_to_present();
	
}


if (can_control) { //control logic (basic, probably will be phased out)
// Check for key presses
var left_key = keyboard_check(vk_left);
var right_key = keyboard_check(vk_right);
var up_key = keyboard_check(vk_up);
var down_key = keyboard_check(vk_down);

// Set movement speed
var move_speed = 4;

// Move the object based on key presses
if (left_key) {
    x -= move_speed;
}
if (right_key) {
    x += move_speed;
}
if (up_key) {
    y -= move_speed;
}
if (down_key) {
    y += move_speed;
} 

if (other.time_phase != time_phase) {
    exit; // ignore collision
}

}


//quick wallbreak test function

if (keyboard_check_pressed(ord("G")))  // press G to test
{
	
	show_debug_message("Time phase = " + time_phase);
    var wall = instance_nearest(x, y, oWallParent);
    
    if (wall != noone)
    {
        wall.take_damage(wall.wall_hp, DAMAGE_TYPE.BULLET);
    }
}

