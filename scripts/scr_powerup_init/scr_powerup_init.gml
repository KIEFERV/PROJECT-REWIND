function scr_powerup_init(){
var _player = argument0;

if (variable_instance_exists(_player, "powerups")) {
    if (ds_exists(_player.powerups, ds_type_map)) {
        ds_map_destroy(_player.powerups);
    }
}

_player.powerups = ds_map_create();

_player.base_move_speed = 8;
_player.base_fire_delay = 15;

_player.move_speed = _player.base_move_speed;
_player.fire_delay = _player.base_fire_delay;

_player.can_ricochet = false;
_player.can_place_cover = false;
_player.can_gravity_shot = false;
_player.max_cover_count = 0;
}