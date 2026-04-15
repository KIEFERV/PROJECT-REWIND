var old_x = x;
var old_y = y;

// move
x += lengthdir_x(speed, direction);
y += lengthdir_y(speed, direction);

// hit wall or cover
if (place_meeting(x, y, obj_wall) || place_meeting(x, y, obj_cover)) {

    if (is_gravity_shot) {
        scr_spawn_gravity_field(x, y, gravity_radius, gravity_duration, gravity_pull, owner);
        instance_destroy();
        exit;
    }

    if (can_ricochet && ricochet_count > 0) {
        x = old_x;
        y = old_y;

        var hit_h = place_meeting(x + lengthdir_x(speed, direction), y, obj_wall)
                 || place_meeting(x + lengthdir_x(speed, direction), y, obj_cover);

        var hit_v = place_meeting(x, y + lengthdir_y(speed, direction), obj_wall)
                 || place_meeting(x, y + lengthdir_y(speed, direction), obj_cover);

        if (hit_h) direction = 180 - direction;
        if (hit_v) direction = -direction;

        ricochet_count--;
    } else {
        instance_destroy();
    }
}

// outside room
if (x < -32 || x > room_width + 32 || y < -32 || y > room_height + 32) {
    if (is_gravity_shot) {
        scr_spawn_gravity_field(x, y, gravity_radius, gravity_duration, gravity_pull, owner);
    }
    instance_destroy();
}