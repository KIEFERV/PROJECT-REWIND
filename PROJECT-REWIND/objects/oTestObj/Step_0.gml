event_inherited();



if (keyboard_check_pressed(ord("Z")) && !rewind_active) { //Rewind phase logic
	
	rewind = true;
	rewind_active = true;
	can_control = true;
	visible = true;  // optional, hide original player
	image_alpha = 0.5; // semi-transparent

    // Spawn ghost in past
    var ghost = instance_create_layer(x, y, layer, oTestObj);
    ghost.can_control = false;

}


if (can_control) {
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
