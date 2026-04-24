function scr_powerup_add(){
var _player = argument0;
var _power_name = argument1;
var _duration_steps = argument2;
var _magnitude = argument3;

if (!variable_instance_exists(_player, "powerups")) {
    scr_powerup_init(_player);
}

var expire_time = current_time + (_duration_steps * (1000 / room_speed));
var value = string(expire_time) + "|" + string(_magnitude);

ds_map_replace(_player.powerups, _power_name, value);
scr_powerup_apply_stats(_player);
}