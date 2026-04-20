if (is_gravity_shot) {
    draw_set_color(make_color_rgb(140, 180, 255));
    draw_circle(x, y, 8, false);
    draw_set_color(c_white);
    draw_circle(x, y, 4, false);
} else {
    draw_set_color(c_yellow);
    draw_circle(x, y, 3, false);
}