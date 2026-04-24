function scr_powerup_time_left(){
var _player = argument0;
var _power_name = argument1;

if (!variable_instance_exists(_player, "powerups")) return 0;
if (!ds_map_exists(_player.powerups, _power_name)) return 0;

var value = ds_map_find_value(_player.powerups, _power_name);
var sep = string_pos("|", value);
var expire_time = real(string_copy(value, 1, sep - 1));

return max(0, (expire_time - current_time) / 1000);
}