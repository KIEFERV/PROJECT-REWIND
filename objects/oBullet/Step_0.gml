/// oBullet Step_0
/*
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

//Bullets not equal to your state cannot be seen.


if (time_phase != oPlayerHitbox.time_phase && !is_ghost){
	image_alpha = 0;
} else if (is_ghost){
	image_alpha = 0.35;
}else{
	image_alpha = 1;
}

// Despawn when out of bounds
if (x < 0 || x > room_width || y < 0 || y > room_height) {
	
	if (is_gravity_shot) {
        scr_spawn_gravity_field(x, y, gravity_radius, gravity_duration, gravity_pull, owner);
    }
	
    instance_destroy();
}
*/
image_angle = direction;

if (!variable_instance_exists(id,"is_gravity_shot")) is_gravity_shot = false;

if (!variable_instance_exists(id,"gravity_radius")) gravity_radius = 140;

if (!variable_instance_exists(id,"gravity_duration")) gravity_duration = room_speed * 2;

if (!variable_instance_exists(id,"gravity_pull")) gravity_pull = 1.1;

if (!variable_instance_exists(id,"can_ricochet")) can_ricochet = false;

if (!variable_instance_exists(id,"ricochet_count")) ricochet_count = 0;

if (!variable_instance_exists(id,"is_ghost")) is_ghost = false;

if (!variable_instance_exists(id,"time_phase")) time_phase = "present";

var old_x = x;

var old_y = y;

x += lengthdir_x(speed,direction);

y += lengthdir_y(speed,direction);

var hit = false;

if (place_meeting(x,y,oWall)) hit = true;

if (place_meeting(x,y,obj_cover_powerup)) hit = true;

if (hit) {

    if (is_gravity_shot) {

        scr_spawn_gravity_field(x,y,gravity_radius,gravity_duration,gravity_pull,owner);

        instance_destroy();

        exit;

    }

    if (can_ricochet && ricochet_count > 0) {

        x = old_x;

        y = old_y;

        var hit_h = place_meeting(x + lengthdir_x(speed,direction),y,oWall) || place_meeting(x + lengthdir_x(speed,direction),y,obj_cover_powerup);

        var hit_v = place_meeting(x,y + lengthdir_y(speed,direction),oWall) || place_meeting(x,y + lengthdir_y(speed,direction),obj_cover_powerup);

        if (hit_h) direction = 180 - direction;

        if (hit_v) direction = -direction;

        image_angle = direction;

        ricochet_count--;

    } else {

        instance_destroy();

        exit;

    }

}

var margin = 32;

if (x < -margin || x > room_width + margin || y < -margin || y > room_height + margin) {

    if (is_gravity_shot) {

        scr_spawn_gravity_field(x,y,gravity_radius,gravity_duration,gravity_pull,owner);

    }

    instance_destroy();

    exit;

}

// Visibility by time phase

var viewer_phase = "present";

if (instance_exists(oPlayerHitbox)) {

    viewer_phase = oPlayerHitbox.time_phase;

}

if (time_phase != viewer_phase && !is_ghost) {

    image_alpha = 0;

} else if (is_ghost) {

    image_alpha = 0.35;

} else {

    image_alpha = 1;

}

