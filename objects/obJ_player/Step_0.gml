scr_powerup_update(self);


var h = keyboard_check(ord("D")) - keyboard_check(ord("A"));
var v = keyboard_check(ord("S")) - keyboard_check(ord("W"));

var len = point_distance(0, 0, h, v);
if (len > 0) {
    h /= len;
    v /= len;
}

x += h * move_speed;
y += v * move_speed;

// shooting timer
if (shoot_timer > 0) shoot_timer--;
if (cover_cooldown > 0) cover_cooldown--;


if (mouse_check_button(mb_left) && shoot_timer <= 0) {
    var b = instance_create_layer(x, y, "Instances", obj_bullet);
    b.direction = point_direction(x, y, mouse_x, mouse_y);
    b.speed = 10;
    b.owner = id;
    b.can_ricochet = can_ricochet;
    b.ricochet_count = can_ricochet ? 2 : 0;

    shoot_timer = fire_delay;
}

// place cover with space 
if (keyboard_check_pressed(vk_space) && can_place_cover && cover_cooldown <= 0) {
    var cx = x + lengthdir_x(32, image_angle);
    var cy = y + lengthdir_y(32, image_angle);

    instance_create_layer(cx, cy, "Instances", obj_cover);
    cover_cooldown = room_speed; // 1 second cooldown
}