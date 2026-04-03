var gui_w = display_get_gui_width();
var gui_h = display_get_gui_height();


draw_sprite_stretched(spr_time_bg, 0, 0, 0, gui_w, gui_h);


draw_set_alpha(0.55);
draw_set_color(make_color_rgb(10,12,18));
draw_rectangle(0,0,gui_w,gui_h,false);
draw_set_alpha(1);

var panel_x = 60;
var panel_y = 50;
var panel_w = gui_w - 120;
var panel_h = gui_h - 100;

draw_set_alpha(0.92);
draw_set_color(make_color_rgb(18,20,28));
draw_rectangle(panel_x, panel_y, panel_x + panel_w, panel_y + panel_h, false);

// subtle border
draw_set_color(make_color_rgb(80,100,170));
draw_rectangle(panel_x, panel_y, panel_x + panel_w, panel_y + panel_h, true);

draw_set_alpha(1);

draw_set_color(c_white);
draw_text(panel_x + 20, panel_y + 20, "Browse Lobbies");

draw_set_color(make_color_rgb(208, 212, 237));
draw_text(panel_x + 20, panel_y + 45, "UP/DOWN = select | ENTER = join | ESC = back");

var start_y = panel_y + 80;
var item_h = 60;

if (array_length(lobbies) == 0) {
    draw_set_color(c_white);
    draw_text(panel_x + 20, start_y, status_text);
} else {
    for (var i = 0; i < array_length(lobbies); i++) {
        var ly = start_y + i * item_h;

        draw_set_color(i == selected_index ? make_color_rgb(249, 37, 37) : c_white);
        draw_rectangle(panel_x + 20, ly, panel_x + panel_w - 20, ly + 45, true);

        draw_set_color(c_white);
        draw_text(panel_x + 30, ly + 8, lobbies[i].name);
        draw_text(panel_x + 250, ly + 8, "Players: " + string(lobbies[i].max_participants));
        draw_text(panel_x + 30, ly + 25, lobbies[i].description);
    }
}

draw_set_color(c_white);
draw_text(panel_x + 20, panel_y + panel_h - 20, status_text);