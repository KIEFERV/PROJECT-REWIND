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


// Sprinting
var modifier_sprint;
if (key_sprint && can_sprint && !key_sneak){
	// Player is Sprinting
	sprinting = true;
	sprint_speed = 1.5;
}else{
	sprinting = false;
	sprint_speed = 1.0;
}
//Walking
var sneak_speed;
if (key_sneak && !key_sprint){
	sneaking = true;
	sneak_speed = 0.5;
}else{
	sneaking = false;
	sneak_speed = 1.0;
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

// Player collision after speed multipliers
// Horizontal (x-axis)
if place_meeting(x + player_hor_speed, y, oCollisionBox){
	player_hor_speed = 0; //this is not affecting sprint
}
// Vertical (y-axis)
if place_meeting(x, y + player_vert_speed, oCollisionBox){
	player_vert_speed = 0; //this is not affecting sprint
}

// Move the player
x += player_hor_speed;
y += player_vert_speed;

// Set the audio listener position
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



/*
#region Locomotion

	var _list = ds_list_create(),
		_x_axis = keyboard_check(ord("D")) - keyboard_check(ord("A")),
		_y_axis = keyboard_check(ord("S")) - keyboard_check(ord("W")),
		_velocity_x = 0,
		_velocity_y = 0;
	
	if (_x_axis != 0 || _y_axis != 0)
	{
		var _dir = arctan2(_y_axis, _x_axis);
		_velocity_x = cos(_dir) * 6;
		_velocity_y = sin(_dir) * 6;
	}

#endregion

#region Horizontal move/collisions

	x += _velocity_x;
	var _collisions = instance_place_list(x + sign(_velocity_x), y, __collider, _list, false); //COLLIDER DOESNT EXIST YET
	
	if (_collisions)
	{
		var _resolved_x = x;
		if (_velocity_x > 0)
		{
			// Loop through collisions and find the min x value
			for (var _i = 0; _i < _collisions; _i++)
				_resolved_x = min(_resolved_x, _list[| _i].bbox_left + x - bbox_right);
		}
		else if (_velocity_x < 0)
		{
			// Loop through collisions and find the max x value
			for (var _i = 0; _i < _collisions; _i++)
				_resolved_x = max(_resolved_x, _list[| _i].bbox_right + x - bbox_left);
		}
		x = _resolved_x;
	}

#endregion

#region Vertical move/collisions

	y += _velocity_y;
	ds_list_clear(_list);
	_collisions = instance_place_list(x, y + sign(_velocity_y), __collider, _list, false);

	if (_collisions)
	{
		var _resolved_y = y;
		if (_velocity_y > 0)
		{
			// Loop through collisions and find the min y value
			for (var _i = 0; _i < _collisions; _i++)
				_resolved_y = min(_resolved_y, _list[| _i].bbox_top + y - bbox_bottom);	
		}
		else if (_velocity_y < 0)
		{
			// Loop through collisions and find the max y value
			for (var _i = 0; _i < _collisions; _i++)
				_resolved_y = max(_resolved_y,_list[| _i].bbox_bottom + y - bbox_top);
		}
		y = _resolved_y;
	}

	ds_list_destroy(_list);

#endregion



var _input_x = keyboard_check(ord("D")) - keyboard_check(ord("A")),
	_input_y = keyboard_check(ord("S")) - keyboard_check(ord("W"));
	
	*/
	
var _input_x = keyboard_check(ord("D")) - keyboard_check(ord("A")),
	_input_y = keyboard_check(ord("S")) - keyboard_check(ord("W"));

add_movement_input(_input_x, _input_y);

event_inherited();





