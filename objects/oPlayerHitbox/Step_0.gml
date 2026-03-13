///@description Player Logic

#region Keybinds
//set movement keybinds
var _input_x = keyboard_check(ord("D")) - keyboard_check(ord("A")),
	_input_y = keyboard_check(ord("S")) - keyboard_check(ord("W"));
	
key_sprint = keyboard_check(vk_shift);
key_sneak = keyboard_check(vk_alt);
if (keyboard_check_released(ord("M"))){debug_menu = !debug_menu;}
#endregion

#region Player States



//Sprinting
var modifier_sprint;
if (key_sprint && can_sprint && !key_sneak){
	// Player is Sprinting
	sprinting = true;
	can_sneak = false
	modifier_sprint = 1.5;
}else{
	// Player is not Sprinting
	sprinting = false;
	can_sneak = true;
	modifier_sprint = 1.0;
}

//Walking
var modifier_sneak;
if (key_sneak && can_sneak && !key_sprint){
	// Player is Sneaking
	sneaking = true;
	can_sprint = false;
	modifier_sneak = 0.5;
}else{
	// Player is not Sneaking
	sneaking = false;
	can_sprint = true;
	modifier_sneak = 1.0;
}

// Touching Slippery Floor
var modifier_floor_slippery_accel,
	modifier_floor_slippery_decel,
	modifier_floor_slippery_max;
if (place_meeting(x, y, oFloorSlippery)) {
	// Player is Slipping
	// add sliding check boolean here??
	modifier_floor_slippery_accel = 0.1;
	modifier_floor_slippery_decel = 0.05;
	modifier_floor_slippery_max = 0.8;
	
}else{
	// Player is not Slipping
	modifier_floor_slippery_accel = 1.0;
	modifier_floor_slippery_decel = 1.0;
	modifier_floor_slippery_max = 1.0;
}

// Touching Slowing Floor
var modifier_floor_slow_max,
	modifier_floor_slow_accel;
if (place_meeting(x, y, oFloorSlow)){
	// Player is Slowed
	// add slow check boolean here?
	modifier_floor_slow_max = 0.5;
	modifier_floor_slow_accel = 0.8;
}else{
	//Player is not Slowed
	modifier_floor_slow_max = 1.0;
	modifier_floor_slow_accel = 1.0;
}

// Touching Boost Floor
var modifier_floor_boost_max,
	modifier_floor_boost_accel;
if (place_meeting(x, y, oFloorBoost)){
	// Player is Boosting
	// add boosting check boolean here?
	modifier_floor_boost_max = 1.2;
	modifier_floor_boost_accel = 1.1;
}else{
	// Player is not Boosting
	modifier_floor_boost_max = 1.0;
	modifier_floor_boost_accel = 1.0;
}
#endregion


//set the audio listener position
audio_listener_position(x, y, 0);

#region Modifiers

// Max Movement Speed
move_speed_max = (base_move_speed_max
	* modifier_sprint
	* modifier_sneak
	* modifier_floor_slow_max
	* modifier_floor_slippery_max
	* modifier_floor_boost_max
);

// Movement Acceleration
move_accel = (base_move_accel
	* modifier_floor_slippery_accel
	* modifier_floor_slow_accel
	* modifier_floor_boost_accel
);

// Movement Deceleration
move_decel = (base_move_decel
	* modifier_floor_slippery_decel
);

#endregion

//move the player
add_movement_input(_input_x, _input_y);

//inherit the code from parent (oCharacterController)
event_inherited();