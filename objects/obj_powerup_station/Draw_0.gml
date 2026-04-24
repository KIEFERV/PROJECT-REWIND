if (!variable_instance_exists(id, "current_power")) exit;

var col = c_white;

switch (current_power) {
    case global.POWER_FIRE_RATE:
        col = make_color_rgb(255, 90, 90);
    break;

    case global.POWER_MOVE_SPEED:
        col = make_color_rgb(90, 255, 120);
    break;

    case global.POWER_RICOCHET:
        col = make_color_rgb(90, 170, 255);
    break;

    case global.POWER_COVER:
        col = make_color_rgb(180, 180, 255);
    break;

    case global.POWER_GRAVITY_SHOT:
        col = make_color_rgb(140, 180, 255);
    break;
}

var active = cooldown_timer <= 0;
var pulse = 0.5 + 0.5 * sin(current_time * 0.008);

if (!active) {
    col = make_color_rgb(80, 80, 90);
}

draw_set_alpha(active ? 0.25 + pulse * 0.15 : 0.15);
draw_set_color(col);
draw_circle(x, y, 32, false);

draw_set_alpha(1);
draw_set_color(col);
draw_rectangle(x - 14, y - 14, x + 14, y + 14, false);

draw_set_color(c_black);
draw_text(x - 4, y - 10, "!");

if (!active) {
    draw_set_color(c_white);
    var seconds_left = ceil(cooldown_timer / room_speed);
    draw_text(x - 18, y + 22, string(seconds_left) + "s");
}

draw_set_alpha(1);
draw_set_color(c_white);