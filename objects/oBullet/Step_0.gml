//direction
image_angle = direction;

//despawn
if (x < 0 || x > room_width || y < 0 || y > room_height)
{
	emitAudio(x, y, sfxPop); //debug - remove later
    instance_destroy();
	
}
var old_x = x;
var old_y = y;

x += lengthdir_x(speed, direction);
y += lengthdir_y(speed, direction);

var hit_wall = false;

if (object_exists(oWall)) {
    if (place_meeting(x, y, oWall)) hit_wall = true;
}

if (object_exists(obj_cover_powerup)) {
    if (place_meeting(x, y, obj_cover_powerup)) hit_wall = true;
}

if (hit_wall) {
    if (is_gravity_shot) {
        scr_spawn_gravity_field(x, y, gravity_radius, gravity_duration, gravity_pull, owner);
        instance_destroy();
        exit;
    }

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

        ricochet_count--;
    } else {
        instance_destroy();
    }
}

if (x < -32 || x > room_width + 32 || y < -32 || y > room_height + 32) {
    if (is_gravity_shot) {
        scr_spawn_gravity_field(x, y, gravity_radius, gravity_duration, gravity_pull, owner);
    }

    instance_destroy();
}