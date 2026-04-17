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

// Look Direction
facing = point_direction(x, y, mouse_x, mouse_y);

// Sprinting
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

// Walking
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
var event = oMatchEvent.event_current;
var wind_dir = oMatchEvent.event_wind_dir,
	wind_power = oMatchEvent.event_wind_power;

if(event == "wind"){
	add_impulse_direction(wind_dir, wind_power);
}

#endregion


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

#endregion

#region Shooting

// hitbox
//x = oPlayerHitbox.x; //no longer needed
//y = oPlayerHitbox.y; // no longer needed

//rotation
image_angle = point_direction(x, y, mouse_x, mouse_y);

//shooting
if (mouse_check_button_pressed(mb_left))
{
    if (!reloading && ammo_in_mag > 0)
    {
		//var mydir = point_direction(x, y, mouse_x, mouse_y);
        spawnBullet(x, y, image_angle);
        ammo_in_mag -= 1;
		
		//DEBUG - tell the server we fired a bullet
		//var buf = buffer_create(16, buffer_fixed, 1);
		var buf = buffer_create(10, buffer_grow, 1);
		buffer_seek(buf, buffer_seek_start, 0);
		buffer_write(buf, buffer_u8, 4);         // type = 4
		buffer_write(buf, buffer_f32, x);        // spawn x
		buffer_write(buf, buffer_f32, y);        // spawn y
		buffer_write(buf, buffer_u8,  round((facing / 360.0) * 255)); // direction packed
		
		//show_debug_message("Sending bullet: x=" + string(x) + " y=" + string(y) + " dir=" + string(facing) + " bytes=" + string(buffer_tell(buf)));
		var ip = global.ip_address,
			port = global.port;
		network_send_udp_raw(socket, ip, port, buf, buffer_tell(buf));
		
		buffer_delete(buf);
    }
}


//reload
if (keyboard_check_pressed(ord("R")))
{
    if (!reloading && ammo_in_mag < mag_size && ammo_reserve > 0)
    {
        reloading = true;
        reload_timer = reload_time;
    }
}

if (reloading)
{
    reload_timer -= 1;

    if (reload_timer <= 0)
    {
        var needed = mag_size - ammo_in_mag;
        var loaded = min(needed, ammo_reserve);

        ammo_in_mag += loaded;
        ammo_reserve -= loaded;

        reloading = false;
    }
}

#endregion

// Applies the movement logic (Character_lib) to the player
add_movement_input(_input_x, _input_y);


#region Networking

var buf = buffer_create(32, buffer_fixed, 1);
buffer_seek(buf, buffer_seek_start, 0);

buffer_write(buf, buffer_u8,  1);           // type = 1 (player state)
buffer_write(buf, buffer_f32, x);           // x position
buffer_write(buf, buffer_f32, y);           // y position
buffer_write(buf, buffer_u8,  hitpoints);   // health (0-255)
buffer_write(buf, buffer_u8,  image_index); // animation frame (unused for now)
buffer_write(buf, buffer_u8,  round((facing / 360.0) * 255)); // facing angle

var ip = global.ip_address,
	port = global.port;
network_send_udp_raw(socket, ip, port, buf, buffer_tell(buf));
buffer_delete(buf);

#endregion

#region
// Trigger the shift on keypress
if (keyboard_check_pressed(ord("Z")) && time_phase == "present") {
    if (!rewind_active) {
        plr_travel_start();
    }
}

// Return condition is checked independently, on its own terms
if (time_phase == "past") {
    // Advance the replay head
   buffer_read_index = (buffer_read_index + 1) mod buffer_size;
    past_frames_elapsed++;
    if (past_frames_elapsed >= past_duration) { // actual catch-up condition 
        return_to_present();
    }
}

#endregion

//inherit the code from parent (oCharacterController)
event_inherited();