/// oBullet Create_0

speed       = 12;
image_angle = direction;
owner_id = noone;
time_phase = "present";
is_ghost = false;
damage = 1; // overwritten based on active weapon
// in some init object or game start
global.bullet_id_counter = 0;

event_inherited();
global.bullet_id_counter++;
bullet_id = global.bullet_id_counter;

rewind_get_state = function(idx) {
    bullet_rewind_buffer(idx);
}

