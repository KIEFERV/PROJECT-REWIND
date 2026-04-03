function scr_powerup_init(){
var _player = argument0;

_player.powerups = ds_map_create();

// base stats
_player.base_move_speed = 4;
_player.base_fire_delay = 15;

// current effective stats
_player.move_speed = _player.base_move_speed;
_player.fire_delay = _player.base_fire_delay;

// extra flags
_player.can_ricochet = false;
_player.can_place_cover = false;

}