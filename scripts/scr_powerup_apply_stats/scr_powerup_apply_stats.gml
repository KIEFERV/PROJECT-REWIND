function scr_powerup_apply_stats(){

var _player = argument0;

// reset to defaults
_player.move_speed = _player.base_move_speed;
_player.fire_delay = _player.base_fire_delay;
_player.can_ricochet = false;
_player.can_place_cover = false;

var _keys = ds_map_keys_to_array(_player.powerups);

for (var i = 0; i < array_length(_keys); i++) {
    var _key = _keys[i];
    var _value = ds_map_find_value(_player.powerups, _key);

    var _sep = string_pos("|", _value);
    var _mag = real(string_copy(_value, _sep + 1, string_length(_value) - _sep));

    switch (_key) {
        case global.POWER_MOVE_SPEED:
            _player.move_speed = _player.base_move_speed + _mag;
        break;

        case global.POWER_FIRE_RATE:
            _player.fire_delay = max(1, _player.base_fire_delay - _mag);
        break;

        case global.POWER_RICOCHET:
            _player.can_ricochet = true;
        break;

        case global.POWER_COVER:
            _player.can_place_cover = true;
        break;
    }
}
}