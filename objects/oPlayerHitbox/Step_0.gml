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

//Player Death
if (hitpoints <= 0){
	dead_state = true;
}else{
	dead_state = false;
}
	

// Look Direction
facing = point_direction(x, y, mouse_x, mouse_y);

// Sprinting
var modifier_sprint;
if (key_sprint && can_sprint && !key_sneak){
	sprinting = true;
	can_sneak = false;
	modifier_sprint = 1.5;
}else{
	sprinting = false;
	can_sneak = true;
	modifier_sprint = 1.0;
}

// Walking
var modifier_sneak;
if (key_sneak && can_sneak && !key_sprint){
	sneaking = true;
	can_sprint = false;
	modifier_sneak = 0.5;
}else{
	sneaking = false;
	can_sprint = true;
	modifier_sneak = 1.0;
}

// Touching Slippery Floor
var modifier_floor_slippery_accel,
	modifier_floor_slippery_decel,
	modifier_floor_slippery_max;
if (place_meeting(x, y, oFloorSlippery)) {
	modifier_floor_slippery_accel = 0.1;
	modifier_floor_slippery_decel = 0.05;
	modifier_floor_slippery_max   = 0.8;
}else{
	modifier_floor_slippery_accel = 1.0;
	modifier_floor_slippery_decel = 1.0;
	modifier_floor_slippery_max   = 1.0;
}

// Touching Slowing Floor
var modifier_floor_slow_max,
	modifier_floor_slow_accel;
if (place_meeting(x, y, oFloorSlow)){
	modifier_floor_slow_max   = 0.5;
	modifier_floor_slow_accel = 0.8;
}else{
	modifier_floor_slow_max   = 1.0;
	modifier_floor_slow_accel = 1.0;
}

// Touching Boost Floor
var modifier_floor_boost_max,
	modifier_floor_boost_accel;
if (place_meeting(x, y, oFloorBoost)){
	modifier_floor_boost_max   = 1.2;
	modifier_floor_boost_accel = 1.1;
}else{
	modifier_floor_boost_max   = 1.0;
	modifier_floor_boost_accel = 1.0;
}

#endregion

// Set the audio listener position
audio_listener_position(x, y, 0);

#region Modifiers

move_speed_max = (base_move_speed_max
	* modifier_sprint
	* modifier_sneak
	* modifier_floor_slow_max
	* modifier_floor_slippery_max
	* modifier_floor_boost_max
);

move_accel = (base_move_accel
	* modifier_floor_slippery_accel
	* modifier_floor_slow_accel
	* modifier_floor_boost_accel
);

move_decel = (base_move_decel
	* modifier_floor_slippery_decel
);

#endregion

#region Shooting

//player_look_dir = point_direction(x, y, mouse_x, mouse_y);
//image_angle = 0;

if (mouse_check_button_pressed(mb_left))
{
    if (!reloading && ammo_in_mag > 0)
    {
        spawnBullet(x, y, facing, id);
        ammo_in_mag -= 1;

        var buf = buffer_create(10, buffer_grow, 1);
        buffer_seek(buf, buffer_seek_start, 0);
        buffer_write(buf, buffer_u8,  4);
        buffer_write(buf, buffer_f32, x);
        buffer_write(buf, buffer_f32, y);
        buffer_write(buf, buffer_u8,  round((facing / 360.0) * 255));
        network_send_udp_raw(global.socket, global.ip_address, global.port,
                             buf, buffer_tell(buf));
        buffer_delete(buf);
    }
}

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
        ammo_in_mag   += loaded;
        ammo_reserve  -= loaded;
        reloading = false;
    }
}

#endregion

// Applies the movement logic (Character_lib) to the player
add_movement_input(_input_x, _input_y);

#region Networking
// Throttled to 20 sends/sec — every 3 steps at 60fps.
// Raise the divisor for smoother remote movement (uses more bandwidth).
net_send_timer++;
if (net_send_timer >= game_get_speed(gamespeed_fps) / 20) {
    net_send_timer = 0;

    var buf = buffer_create(32, buffer_fixed, 1);
    buffer_seek(buf, buffer_seek_start, 0);
    buffer_write(buf, buffer_u8,  1);
    buffer_write(buf, buffer_f32, x);
    buffer_write(buf, buffer_f32, y);
    buffer_write(buf, buffer_u8,  hitpoints);
    buffer_write(buf, buffer_u8,  image_index);
    buffer_write(buf, buffer_u8,  round((facing / 360.0) * 255));
    network_send_udp_raw(global.socket, global.ip_address, global.port,
                         buf, buffer_tell(buf));
    buffer_delete(buf);
}
#endregion

#region Time rewind
if (keyboard_check_pressed(ord("Z")) && time_phase == "present") {
    if (!rewind_active) {
        plr_travel_start();
    }
}

if (time_phase == "past") {
    buffer_read_index = (buffer_read_index + 1) mod buffer_size;
    past_frames_elapsed++;
    if (past_frames_elapsed >= past_duration) {
        return_to_present();
    }
}
#endregion

//inherit the code from parent (oCharacterController)
event_inherited();
