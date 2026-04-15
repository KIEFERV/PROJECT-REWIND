function scr_powerup_update(){

var _player = argument0;

var _keys = ds_map_keys_to_array(_player.powerups);
var _changed = false;

for (var i = 0; i < array_length(_keys); i++) {
    var _key = _keys[i];
    var _value = ds_map_find_value(_player.powerups, _key);

    var _sep = string_pos("|", _value);
    var _expire = real(string_copy(_value, 1, _sep - 1));

    if (current_time > _expire) {
        ds_map_delete(_player.powerups, _key);
        _changed = true;
    }
}

if (_changed) {
    scr_powerup_apply_stats(_player);
}


}