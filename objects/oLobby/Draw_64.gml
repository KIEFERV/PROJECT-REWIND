draw_set_font(-1);
draw_set_halign(fa_center);
draw_set_color(c_white);

draw_text(display_get_gui_width() / 2, 100, "LOBBY");
draw_text(display_get_gui_width() / 2, 160, status_msg);


if (is_host) {
    draw_text(display_get_gui_width() / 2, 320, "SPACE — start match");
}