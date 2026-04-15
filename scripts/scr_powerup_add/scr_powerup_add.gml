function scr_powerup_add(){
var _player = argument0;
var _power_name = argument1;
var _duration = argument2;
var _magnitude = argument3;

var _expire_time = current_time + (_duration * (1000 / room_speed));


var _value = string(_expire_time) + "|" + string(_magnitude);
ds_map_replace(_player.powerups, _power_name, _value);

// re-apply stats immediately
scr_powerup_apply_stats(_player);
}