//direction
image_angle = direction;

//despawn
var margin = 32;

if (x < -margin || x > room_width + margin || y < -margin || y > room_height + margin) {
    if (is_gravity_shot) {
        scr_spawn_gravity_field(x, y, gravity_radius, gravity_duration, gravity_pull, owner);
    }
    instance_destroy();
}
var old_x = x;
var old_y = y;

// Move
x += lengthdir_x(speed, direction);
y += lengthdir_y(speed, direction);

var hit = false;

// Wall collision
if (object_exists(oWall)) {
    if (place_meeting(x, y, oWall)) hit = true;
}

// Cover collision
if (object_exists(obj_cover_powerup)) {
    if (place_meeting(x, y, obj_cover_powerup)) hit = true;
}

// --- IMPACT ---
if (hit) {

    // Gravity shot effect
    if (is_gravity_shot) {
        scr_spawn_gravity_field(x, y, gravity_radius, gravity_duration, gravity_pull, owner);
        instance_destroy();
        exit;
    }

    // Ricochet logic
    if (can_ricochet && ricochet_count > 0) {

        x = old_x;
        y = old_y;

        var hit_h = false;
        var hit_v = false;

        if (object_exists(oWall)) {
            hit_h = place_meeting(x + lengthdir_x(speed, direction), y, oWall);
            hit_v = place_meeting(x, y + lengthdir_y(speed, direction), oWall);
        }

        if (object_exists(obj_cover_powerup)) {
            hit_h = hit_h || place_meeting(x + lengthdir_x(speed, direction), y, obj_cover_powerup);
            hit_v = hit_v || place_meeting(x, y + lengthdir_y(speed, direction), obj_cover_powerup);
        }

        if (hit_h) direction = 180 - direction;
        if (hit_v) direction = -direction;

        image_angle = direction;

        ricochet_count--;
    }
    else {
        instance_destroy();
    }
}

// --- OUT OF BOUNDS ---
if (x < -32 || x > room_width + 32 || y < -32 || y > room_height + 32) {

    if (is_gravity_shot) {
        scr_spawn_gravity_field(x, y, gravity_radius, gravity_duration, gravity_pull, owner);
    }

    instance_destroy();
}