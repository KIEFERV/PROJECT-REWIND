/// oBullet Create_0

speed       = 12;
image_angle = direction;
owner_id    = noone;
time_phase  = " ";
is_ghost    = false;
damage      = 1;  // overwritten by spawner
image_alpha = 0;

// Unique bullet ID for rewind tracking
if (!variable_global_exists("bullet_id_counter")) global.bullet_id_counter = 0;
global.bullet_id_counter++;
bullet_id = global.bullet_id_counter;

event_inherited();  // sets up rewind_get_state as empty — we override below

// Override rewind state capture with bullet-specific function
rewind_get_state = function(idx) {
    bullet_rewind_buffer(idx);
};  // calls oRewindable Create — sets up rewind base