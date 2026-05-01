/// oBullet Create_0
sprite_index = sBullet;
speed       = 12;
image_angle = direction;

damage = 1; // overwritten based on active weapon


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