///@description Player Logic

///@description Player Logic
/*
//get inputs
key_right = keyboard_check(ord("D"));
key_left = keyboard_check(ord("A"));
key_up = keyboard_check(ord("W"));
key_down = keyboard_check(ord("S"));
key_sprint = keyboard_check(vk_shift);
key_sneak = keyboard_check(vk_alt);

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
	//player states
//Sprinting
var sprint_speed;
if (key_sprint && !key_sneak){
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

	//Apply the movement multipliers
player_hor_speed = base_hor * (sprint_speed) * (sneak_speed);
player_vert_speed = base_vert * (sprint_speed) * (sneak_speed);


<<<<<<< HEAD
//Move player

// Player collision after speed multipliers
// Horizontal (x-axis)
if place_meeting(x + player_hor_speed, y, oCollisionBox){
	player_hor_speed = 0; //this is not affecting sprint
}
// Vertical (y-axis)
=======
//player collision after speed multipliers
//horizontal (x-axis)
if place_meeting(x + player_hor_speed, y, oCollisionBox){
	player_hor_speed = 0; //this is not affecting sprint
}
//vertical (y-axis)
>>>>>>> parent of 1938120 (Dummies n More)
if place_meeting(x, y + player_vert_speed, oCollisionBox){
	player_vert_speed = 0; //this is not affecting sprint
}

<<<<<<< HEAD
// Move the player
=======
//move the player
>>>>>>> parent of 1938120 (Dummies n More)
x += player_hor_speed;
y += player_vert_speed;

//set the audio listener position
audio_listener_position(x, y, 0);

<<<<<<< HEAD
//dead
if (is_dead) exit;

//Weapon logic
var w = current_weapon;

// Fire cooldown
if (w.fire_timer > 0) w.fire_timer--;

// Reload
if (keyboard_check_pressed(ord("R")) && !w.reloading && w.ammo_in_mag < w.mag_size && w.ammo_reserve > 0)
{
    w.reloading = true;
    w.reload_timer = w.reload_time;
}

if (w.reloading)
{
    w.reload_timer--;
    if (w.reload_timer <= 0)
    {
        var needed = w.mag_size - w.ammo_in_mag;
        var load = min(needed, w.ammo_reserve);
        w.ammo_in_mag += load;
        w.ammo_reserve -= load;
        w.reloading = false;
    }
}

// weapon switching
if (keyboard_check_pressed(ord("1"))) current_weapon_index = 0;
if (keyboard_check_pressed(ord("2"))) current_weapon_index = 1;
if (keyboard_check_pressed(ord("3"))) current_weapon_index = 2;

current_weapon = weapons[current_weapon_index];

// shooting
var shoot_pressed = mouse_check_button_pressed(mb_left);
var shoot_held    = mouse_check_button(mb_left);
var trigger       = w.automatic ? shoot_held : shoot_pressed;

if (trigger && !w.reloading && w.fire_timer <= 0 && w.ammo_in_mag > 0)
{
    var base_dir = point_direction(x, y, mouse_x, mouse_y);

var spawn_offset = 8;
var bx = x + lengthdir_x(spawn_offset, base_dir);
var by = y + lengthdir_y(spawn_offset, base_dir);

// spread center
var half_spread = w.spread / 2;

for (var i = 0; i < w.pellets; i++)
{
    var pellet_dir;

    // evenly spaced spread instead of random
    if (w.pellets > 1)
    {
        pellet_dir = base_dir - half_spread + (i * (w.spread / (w.pellets - 1)));
    }
    else
    {
        pellet_dir = base_dir;
    }

    var b = instance_create_layer(bx, by, "Instances", oBullet);
    
    b.direction = pellet_dir;
    b.speed = w.bullet_speed;
    b.image_angle = pellet_dir;
    b.owner = id;
}

    w.ammo_in_mag -= 1;
    w.fire_timer = w.fire_rate;

    //debug message
    show_debug_message("Fired weapon: " + w.name + " Ammo: " + string(w.ammo_in_mag));
    }
*/



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





=======
//detect distance from emitter
//var dist = point_distance(x, y, oAudioEmitter.x, oAudioEmitter.y);
>>>>>>> parent of 1938120 (Dummies n More)
