/// @description Player Logic

#region Keybinds
var _input_x = keyboard_check(ord("D")) - keyboard_check(ord("A")),
    _input_y = keyboard_check(ord("S")) - keyboard_check(ord("W"));

key_sprint = keyboard_check(vk_shift);
key_sneak  = keyboard_check(vk_alt);
if (keyboard_check_released(ord("M"))) { debug_menu = !debug_menu; }
#endregion

#region Player States

facing = point_direction(x, y, mouse_x, mouse_y);

var modifier_sprint;
if (key_sprint && can_sprint && !key_sneak) {
    sprinting      = true;
    can_sneak      = false;
    modifier_sprint = 1.5;
} else {
    sprinting      = false;
    can_sneak      = true;
    modifier_sprint = 1.0;
}

var modifier_sneak;
if (key_sneak && can_sneak && !key_sprint) {
    sneaking       = true;
    can_sprint     = false;
    modifier_sneak = 0.5;
} else {
    sneaking       = false;
    can_sprint     = true;
    modifier_sneak = 1.0;
}

var modifier_floor_slippery_accel, modifier_floor_slippery_decel, modifier_floor_slippery_max;
if (place_meeting(x, y, oFloorSlippery)) {
    modifier_floor_slippery_accel = 0.1;
    modifier_floor_slippery_decel = 0.05;
    modifier_floor_slippery_max   = 0.8;
} else {
    modifier_floor_slippery_accel = 1.0;
    modifier_floor_slippery_decel = 1.0;
    modifier_floor_slippery_max   = 1.0;
}

var modifier_floor_slow_max, modifier_floor_slow_accel;
if (place_meeting(x, y, oFloorSlow)) {
    modifier_floor_slow_max   = 0.5;
    modifier_floor_slow_accel = 0.8;
} else {
    modifier_floor_slow_max   = 1.0;
    modifier_floor_slow_accel = 1.0;
}

var modifier_floor_boost_max, modifier_floor_boost_accel;
if (place_meeting(x, y, oFloorBoost)) {
    modifier_floor_boost_max   = 1.2;
    modifier_floor_boost_accel = 1.1;
} else {
    modifier_floor_boost_max   = 1.0;
    modifier_floor_boost_accel = 1.0;
}

#endregion

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

move_decel = (base_move_decel * modifier_floor_slippery_decel);
#endregion

#region Shooting

image_angle = point_direction(x, y, mouse_x, mouse_y);

if (mouse_check_button_pressed(mb_left)) {
    if (!reloading && ammo_in_mag > 0) {
        spawnBullet(x, y, image_angle);
        ammo_in_mag -= 1;

        // Build bullet packet and send directly to every known peer
        var buf_b = buffer_create(10, buffer_grow, 1);
        buffer_write(buf_b, buffer_u8,  4);
        buffer_write(buf_b, buffer_u16, my_pid);
        buffer_write(buf_b, buffer_f32, x);
        buffer_write(buf_b, buffer_f32, y);
        buffer_write(buf_b, buffer_u8,  round((facing / 360.0) * 255));

        var _pid = ds_map_find_first(peer_addrs);
        while (!is_undefined(_pid)) {
            var _addr = ds_map_find_value(peer_addrs, _pid);
            network_send_udp_raw(socket, _addr[0], _addr[1], buf_b, buffer_tell(buf_b));
            _pid = ds_map_find_next(peer_addrs, _pid);
        }
        buffer_delete(buf_b);
    }
}

if (keyboard_check_pressed(ord("R"))) {
    if (!reloading && ammo_in_mag < mag_size && ammo_reserve > 0) {
        reloading    = true;
        reload_timer = reload_time;
    }
}

if (reloading) {
    reload_timer -= 1;
    if (reload_timer <= 0) {
        var needed = mag_size - ammo_in_mag;
        var loaded = min(needed, ammo_reserve);
        ammo_in_mag   += loaded;
        ammo_reserve  -= loaded;
        reloading = false;
    }
}

#endregion

add_movement_input(_input_x, _input_y);

#region Networking — send state directly to each peer

// Only send if we have at least one peer
if (ds_map_size(peer_addrs) > 0) {
    var buf_s = buffer_create(12, buffer_fixed, 1);
    buffer_write(buf_s, buffer_u8,  1);                              // type 1
    buffer_write(buf_s, buffer_u16, my_pid);                         // our pid
    buffer_write(buf_s, buffer_f32, x);
    buffer_write(buf_s, buffer_f32, y);
    buffer_write(buf_s, buffer_u8,  hitpoints);
    buffer_write(buf_s, buffer_u8,  image_index);
    buffer_write(buf_s, buffer_u8,  round((facing / 360.0) * 255));

    var _pid = ds_map_find_first(peer_addrs);
    while (!is_undefined(_pid)) {
        var _addr = ds_map_find_value(peer_addrs, _pid);
        network_send_udp_raw(socket, _addr[0], _addr[1], buf_s, buffer_tell(buf_s));
        _pid = ds_map_find_next(peer_addrs, _pid);
    }
    buffer_delete(buf_s);
}

#endregion

#region Time rewind
if (keyboard_check_pressed(ord("Z")) && time_phase == "present") {
    if (!rewind_active) { plr_travel_start(); }
}

if (time_phase == "past") {
    buffer_read_index = (buffer_read_index + 1) mod buffer_size;
    past_frames_elapsed++;
    if (past_frames_elapsed >= past_duration) { return_to_present(); }
}
#endregion

event_inherited();
