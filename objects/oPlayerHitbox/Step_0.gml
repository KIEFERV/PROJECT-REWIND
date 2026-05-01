///@description Player Logic
if (!instance_exists(oPlayerHitbox)) exit;

// ── Block input during countdown or when dead ─────────────────────────────
// Only block on countdown — player_alive is handled by visibility/dead_state
if (global.match_phase == "countdown" || global.match_phase == "winner") {
    // Still send state packets during countdown
    net_send_timer++;
    if (net_send_timer >= game_get_speed(gamespeed_fps) / 20) {
        net_send_timer = 0;
        var _sbuf = buffer_create(32, buffer_fixed, 1);
        buffer_write(_sbuf, buffer_u8,  1);
        buffer_write(_sbuf, buffer_f32, x);
        buffer_write(_sbuf, buffer_f32, y);
        buffer_write(_sbuf, buffer_u8,  clamp(hitpoints, 0, 255));
        buffer_write(_sbuf, buffer_u8,  image_index);
        buffer_write(_sbuf, buffer_u8,  round((player_look_dir / 360.0) * 255));
        network_send_udp_raw(global.socket, global.ip_address, global.port,
                             _sbuf, buffer_tell(_sbuf));
        buffer_delete(_sbuf);
    }
    exit;
}

// ── Also block if dead (waiting for round end) ────────────────────────────
if (!global.player_alive) exit;
#region Keybinds
var _input_x = keyboard_check(ord("D")) - keyboard_check(ord("A")),
    _input_y = keyboard_check(ord("S")) - keyboard_check(ord("W"));

key_sprint = keyboard_check(vk_shift);
key_sneak = keyboard_check(vk_alt);
if (keyboard_check_released(ord("M"))){debug_menu = !debug_menu;}
#endregion

#region Player States

if (hitpoints <= 0) {
    dead_state          = true;
    visible             = false;
    global.player_alive = false;
} else {
    dead_state = false;
}

player_look_dir = point_direction(x, y, mouse_x, mouse_y);

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

var modifier_floor_slow_max,
    modifier_floor_slow_accel;
if (place_meeting(x, y, oFloorSlow)){
    modifier_floor_slow_max   = 0.5;
    modifier_floor_slow_accel = 0.8;
}else{
    modifier_floor_slow_max   = 1.0;
    modifier_floor_slow_accel = 1.0;
}

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

// ── Weapon switching ──────────────────────────────────────────────────────────
var _prev_slot = active_slot;
if (keyboard_check_pressed(ord("1"))) active_slot = 1;
if (keyboard_check_pressed(ord("2"))) active_slot = 2;

if (active_slot != _prev_slot) {
    // Save outgoing slot
    if (_prev_slot == 1) {
        primary_ammo_mag     = ammo_in_mag;
        primary_ammo_reserve = ammo_reserve;
        primary_reloading    = reloading;
        primary_reload_timer = reload_timer;
    } else {
        secondary_ammo_mag     = ammo_in_mag;
        secondary_ammo_reserve = ammo_reserve;
        secondary_reloading    = reloading;
        secondary_reload_timer = reload_timer;
    }
    // Load incoming slot
    var _wname = (active_slot == 1) ? primary_name : secondary_name;
    var _def   = weapon_defs[? _wname];
    mag_size      = _def[? "mag_size"];
    reload_time   = _def[? "reload_time"];
    weapon_type   = _def[? "type"];
    fire_delay    = _def[? "fire_delay"];
    bullet_speed  = _def[? "bullet_speed"];
    bullet_damage = _def[? "damage"];
    if (active_slot == 1) {
        ammo_in_mag  = primary_ammo_mag;
        ammo_reserve = primary_ammo_reserve;
        reloading    = primary_reloading;
        reload_timer = primary_reload_timer;
    } else {
        ammo_in_mag  = secondary_ammo_mag;
        ammo_reserve = secondary_ammo_reserve;
        reloading    = secondary_reloading;
        reload_timer = secondary_reload_timer;
    }
    burst_shots_left  = 0;
    burst_fire_timer  = 0;
    knife_swing_timer = 0;
    shoot_timer       = 0;
}

// ── Shoot timer tick ──────────────────────────────────────────────────────────
if (shoot_timer > 0) shoot_timer--;

// ── Knife ─────────────────────────────────────────────────────────────────────
if (weapon_type == "melee") {
    if (knife_swing_timer > 0) knife_swing_timer--;

    if (mouse_check_button_pressed(mb_left) && shoot_timer <= 0) {
        knife_swing_timer = 12;
        var _knife_hit = false;

        // Check local oPlayerHitbox instances (solo / practice)
        with (oPlayerHitbox) {
            if (id == other.id) continue;
            var _dist = point_distance(other.x, other.y, x, y);
            if (_dist > other.knife_range) continue;
            var _angle_to = point_direction(other.x, other.y, x, y);
            var _diff     = angle_difference(_angle_to, other.player_look_dir);
            if (abs(_diff) > other.knife_arc / 2) continue;
            hitpoints -= 1;
            _knife_hit = true;
        }

        // Check remote players from other_players map (multiplayer)
        var _rpid = ds_map_find_first(other_players);
        repeat (ds_map_size(other_players)) {
            var _entry = other_players[? _rpid];
            if (!is_undefined(_entry)) {
                var _rx = _entry[0];
                var _ry = _entry[1];
                var _dist = point_distance(x, y, _rx, _ry);
                if (_dist <= knife_range) {
                    var _angle_to = point_direction(x, y, _rx, _ry);
                    var _diff     = angle_difference(_angle_to, player_look_dir);
                    if (abs(_diff) <= knife_arc / 2) {
                        _knife_hit = true;
                    }
                }
            }
            _rpid = ds_map_find_next(other_players, _rpid);
        }

        // Send knife hit packet so remote players receive and apply damage
        if (_knife_hit) _send_shoot_packet();

        shoot_timer = fire_delay;
    }
} else {

    // ── Burst internal tick ───────────────────────────────────────────────────
    if (weapon_type == "burst" && burst_shots_left > 0) {
        if (burst_fire_timer > 0) {
            burst_fire_timer--;
        } else {
            if (ammo_in_mag > 0) {
                spawnBullet(x, y, player_look_dir, id);
                ammo_in_mag--;
                _send_shoot_packet();
            }
            burst_shots_left--;
            burst_fire_timer = fire_delay;
        }
    }

    // ── Primary fire ──────────────────────────────────────────────────────────
    if (mouse_check_button_pressed(mb_left) && !reloading && shoot_timer <= 0) {

        if (weapon_type == "auto" || weapon_type == "sniper") {
            if (ammo_in_mag > 0) {
                spawnBullet(x, y, player_look_dir, id);
                ammo_in_mag--;
                shoot_timer = fire_delay;
                _send_shoot_packet();
            }

        } else if (weapon_type == "shotgun") {
            if (ammo_in_mag > 0) {
                var _spread  = 15;
                var _pellets = 5;
                for (var _p = 0; _p < _pellets; _p++) {
                    var _offset = (_p / (_pellets - 1) - 0.5) * _spread;
                    spawnBullet(x, y, player_look_dir + _offset, id);
                }
                ammo_in_mag--;
                shoot_timer = fire_delay;
                _send_shoot_packet();
            }

        } else if (weapon_type == "burst") {
            if (ammo_in_mag > 0 && burst_shots_left == 0) {
                burst_shots_left = 3;
                burst_fire_timer = 0;
                shoot_timer = fire_delay * 6;
            }
        }
    }
}

// ── Reload ────────────────────────────────────────────────────────────────────
if (keyboard_check_pressed(ord("R")) && weapon_type != "melee") {
    if (!reloading && ammo_in_mag < mag_size && ammo_reserve > 0) {
        reloading    = true;
        reload_timer = reload_time;
    }
}

if (reloading) {
    reload_timer--;
    if (reload_timer <= 0) {
        var _needed  = mag_size - ammo_in_mag;
        var _loaded  = min(_needed, ammo_reserve);
        ammo_in_mag  += _loaded;
        ammo_reserve -= _loaded;
        reloading = false;
    }
}

#endregion

// ── Local helper: send shoot packet ──────────────────────────────────────────
function _send_shoot_packet() {
    // Encode weapon type as a byte so receivers spawn correct bullets
    // 0=auto 1=shotgun 2=burst 3=sniper 4=melee
    var _wtype_byte = 0;
    switch (weapon_type) {
        case "auto":    _wtype_byte = 0; break;
        case "shotgun": _wtype_byte = 1; break;
        case "burst":   _wtype_byte = 2; break;
        case "sniper":  _wtype_byte = 3; break;
        case "melee":   _wtype_byte = 4; break;
    }
    var _buf = buffer_create(12, buffer_grow, 1);
    buffer_seek(_buf, buffer_seek_start, 0);
    buffer_write(_buf, buffer_u8,  4);                    // type
    buffer_write(_buf, buffer_f32, x);                    // x
    buffer_write(_buf, buffer_f32, y);                    // y
    buffer_write(_buf, buffer_u8,  round((player_look_dir / 360.0) * 255)); // dir
    buffer_write(_buf, buffer_u8,  _wtype_byte);          // weapon type
    buffer_write(_buf, buffer_f32, bullet_damage);        // damage
    network_send_udp_raw(global.socket, global.ip_address, global.port,
                         _buf, buffer_tell(_buf));
    buffer_delete(_buf);
}

add_movement_input(_input_x, _input_y);

#region Networking
net_send_timer++;
if (net_send_timer >= game_get_speed(gamespeed_fps) / 20) {
    net_send_timer = 0;

    var buf = buffer_create(32, buffer_fixed, 1);
    buffer_seek(buf, buffer_seek_start, 0);
    buffer_write(buf, buffer_u8,  1);
    buffer_write(buf, buffer_f32, x);
    buffer_write(buf, buffer_f32, y);
    buffer_write(buf, buffer_u8,  clamp(hitpoints, 0, 255));
    buffer_write(buf, buffer_u8,  image_index);
    buffer_write(buf, buffer_u8,  round((player_look_dir / 360.0) * 255));
    network_send_udp_raw(global.socket, global.ip_address, global.port,
                         buf, buffer_tell(buf));
    buffer_delete(buf);
}
#endregion

#region Time rewind
if (time_phase == "present" && time_cd > 0){
	time_cd--;
}

if (keyboard_check_pressed(ord("Z")) && time_phase == "present" && time_cd <= 0) {
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

event_inherited();
