function scr_powerup_apply_stats(){
var _player = argument0;

_player.move_speed = _player.base_move_speed;
_player.fire_delay = _player.base_fire_delay;

_player.can_ricochet = false;
_player.can_place_cover = false;
_player.can_gravity_shot = false;
_player.max_cover_count = 0;

if (!variable_instance_exists(_player, "powerups")) return;

var keys = ds_map_keys_to_array(_player.powerups);

for (var i = 0; i < array_length(keys); i++) {
    var key = keys[i];
    var value = ds_map_find_value(_player.powerups, key);

    var sep = string_pos("|", value);
    var mag = real(string_copy(value, sep + 1, string_length(value) - sep));

    switch (key) {
        case global.POWER_MOVE_SPEED:
            _player.move_speed = _player.base_move_speed + mag;
        break;

        case global.POWER_FIRE_RATE:
            _player.fire_delay = max(2, _player.base_fire_delay - mag);
        break;

        case global.POWER_RICOCHET:
            _player.can_ricochet = true;
        break;

        case global.POWER_COVER:
            _player.can_place_cover = true;
            _player.max_cover_count = round(mag);
        break;

        case global.POWER_GRAVITY_SHOT:
            _player.can_gravity_shot = true;
        break;
    }
}
}