var col = c_white;

switch (power_name) {
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

// Floating animation
var bob = sin(degtorad(current_time * 0.15 + id)) * 3;

// Pulsing glow strength
var pulse = 0.5 + 0.5 * sin(current_time * 0.01);

// Outer glow
draw_set_alpha(0.15 + 0.15 * pulse);
draw_set_color(col);
draw_circle(x, y + bob, 16, false);

// Secondary glow ring
draw_set_alpha(0.25 + 0.2 * pulse);
draw_circle(x, y + bob, 12, false);

// Main box
draw_set_alpha(1);
draw_set_color(col);
draw_rectangle(x - 10, y - 10 + bob, x + 10, y + 10 + bob, false);

// Inner highlight (gives depth)
draw_set_alpha(0.3);
draw_set_color(c_white);
draw_rectangle(x - 10, y - 10 + bob, x + 10, y - 5 + bob, false);

// Exclamation mark
draw_set_alpha(1);
draw_set_color(c_black);
draw_text(x - 3, y - 9 + bob, "!");

// Small sparkle effect
for (var i = 0; i < 3; i++) {
    var ang = current_time * 0.2 + i * 120;
    var px = x + lengthdir_x(14, ang);
    var py = y + bob + lengthdir_y(14, ang);

    draw_set_alpha(0.4);
    draw_set_color(make_color_rgb(220, 240, 255));
    draw_circle(px, py, 1, false);
}

// Reset alpha
draw_set_alpha(1);