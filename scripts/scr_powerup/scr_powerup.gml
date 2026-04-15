function scr_powerup(){
	
var _player = argument0;
var _power_name = argument1;

if (!ds_map_exists(_player.powerups, _power_name)) {
    return false;
}

var _value = ds_map_find_value(_player.powerups, _power_name);
var _sep = string_pos("|", _value);
var _expire = real(string_copy(_value, 1, _sep - 1));

if (current_time > _expire) {
    ds_map_delete(_player.powerups, _power_name);
    scr_powerup_apply_stats(_player);
    return false;
}

return true;

}