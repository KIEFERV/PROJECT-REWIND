/// oBullet Create_0

speed       = 12;
image_angle = direction;
owner_id    = noone;
time_phase  = "present";
is_ghost    = false;
damage      = 1;  // overwritten by spawner

// Unique bullet ID for rewind tracking
if (!variable_global_exists("bullet_id_counter")) global.bullet_id_counter = 0;
global.bullet_id_counter++;
bullet_id = global.bullet_id_counter;

event_inherited();
