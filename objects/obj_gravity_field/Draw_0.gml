var alpha_amt = life / (room_speed * 2);
if (alpha_amt < 0) alpha_amt = 0;

draw_set_alpha(0.18 * alpha_amt);
draw_set_color(make_color_rgb(120, 170, 255));
draw_circle(x, y, radius, false);

draw_set_alpha(0.35 * alpha_amt);
draw_set_color(make_color_rgb(180, 220, 255));
draw_circle(x, y, radius * 0.5, false);

draw_set_alpha(1);
draw_set_color(c_white);
draw_circle(x, y, 10, false);