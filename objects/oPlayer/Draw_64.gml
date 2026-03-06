var margin = 20;
var icon_size = 32;

var gui_w = display_get_gui_width();
var gui_h = display_get_gui_height();

var icon_x = gui_w - margin - icon_size;
var icon_y = gui_h - margin - icon_size;

if (reloading)
    draw_set_alpha(0.5);
else
    draw_set_alpha(1);

draw_sprite_ext(sBullet, 0, icon_x, icon_y, 1, 1, 0, c_white, 1);

var ammo_text = string(ammo_in_mag) + " / " + string(ammo_reserve);

if (ammo_in_mag <= 0)
    draw_set_color(c_red);
else
    draw_set_color(c_white);

draw_set_halign(fa_right);
draw_set_valign(fa_middle);

draw_text(icon_x - 10, icon_y + icon_size / 2, ammo_text);

draw_set_alpha(1);
draw_set_color(c_white);