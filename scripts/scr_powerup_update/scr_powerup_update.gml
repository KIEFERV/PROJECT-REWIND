function scr_powerup_update(){
var _player = argument0;

if (!variable_instance_exists(_player, "powerups")) {
    scr_powerup_init(_player);
    return;
}

var keys = ds_map_keys_to_array(_player.powerups);
var changed = false;

for (var i = 0; i < array_length(keys); i++) {
    var key = keys[i];
    var value = ds_map_find_value(_player.powerups, key);

    var sep = string_pos("|", value);
    var expire_time = real(string_copy(value, 1, sep - 1));

    if (current_time >= expire_time) {
        ds_map_delete(_player.powerups, key);
        changed = true;
    }
}

if (changed) {
    scr_powerup_apply_stats(_player);
}

}