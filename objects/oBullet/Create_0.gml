/// oBullet Create_0
/*
speed       = 12;
image_angle = direction;
owner_id    = noone;
time_phase  = " ";
is_ghost    = false;
damage      = 1;  // overwritten by spawner
image_alpha = 0;

// Ownership
owner = noone;
owner_id = -1;

// Ricochet
can_ricochet = false;
ricochet_count = 0;

// Gravity shot
is_gravity_shot = false;
gravity_radius = 0;
gravity_duration = 0;
gravity_pull = 0;

// Unique bullet ID for rewind tracking
if (!variable_global_exists("bullet_id_counter")) global.bullet_id_counter = 0;
global.bullet_id_counter++;
bullet_id = global.bullet_id_counter;

event_inherited();  // sets up rewind_get_state as empty — we override below

// Override rewind state capture with bullet-specific function
rewind_get_state = function(idx) {
    bullet_rewind_buffer(idx);
};  // calls oRewindable Create — sets up rewind base
*/


speed = 12;

direction = 0;

sprite_index = sBullet;

image_angle = direction;

image_alpha = 1;

owner = noone;

owner_id = -1;

damage = 1;

time_phase = "present";

is_ghost = false;

can_ricochet = false;

ricochet_count = 0;

is_gravity_shot = false;

gravity_radius = 140;

gravity_duration = room_speed * 2;

gravity_pull = 1.1;

if (!variable_global_exists("bullet_id_counter")) global.bullet_id_counter = 0;

global.bullet_id_counter++;

bullet_id = global.bullet_id_counter;

event_inherited();

rewind_get_state = function(idx) {

    bullet_rewind_buffer(idx);

};