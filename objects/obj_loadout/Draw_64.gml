var gui_w = display_get_gui_width();
var gui_h = display_get_gui_height();

draw_sprite_stretched(spr_time_bg, 0, 0, 0, gui_w, gui_h);

draw_set_alpha(0.60);
draw_set_color(make_color_rgb(8, 10, 18));
draw_rectangle(0, 0, gui_w, gui_h, false);
draw_set_alpha(1);

var panel_w = 860;
var panel_h = 520;
var panel_x = (gui_w - panel_w) / 2;
var panel_top = (gui_h - panel_h) / 2;

draw_set_alpha(0.92);
draw_set_color(make_color_rgb(18, 20, 30));
draw_rectangle(panel_x, panel_top, panel_x + panel_w, panel_top + panel_h, false);
draw_set_alpha(1);

draw_set_color(make_color_rgb(90, 110, 185));
draw_rectangle(panel_x, panel_top, panel_x + panel_w, panel_top + panel_h, true);

draw_set_color(c_white);
draw_text(panel_x + 320, panel_top + 25, "LOADOUT");
draw_set_color(make_color_rgb(208, 212, 237));
draw_text(panel_x + 255, panel_top + 55, "Choose your weapons before entering the match");

var col1_x = panel_x + 70;
var col2_x = panel_x + 430;
var list_top = panel_top + 120;
var row_h = 42;

draw_set_color(c_white);
draw_text(col1_x, list_top - 35, "Primary Weapon");
draw_text(col2_x, list_top - 35, "Secondary Weapon");

for (var i = 0; i < array_length(primary_list); i++) {
    var row_top = list_top + i * row_h;
    var selected = (i == primary_index);
    var active = (active_column == 0);

    draw_set_color(selected ? make_color_rgb(42, 58, 108) : make_color_rgb(24, 28, 42));
    draw_rectangle(col1_x, row_top, col1_x + 250, row_top + 32, false);

    draw_set_color((selected && active) ? make_color_rgb(255, 100, 100) : make_color_rgb(180, 190, 255));
    draw_rectangle(col1_x, row_top, col1_x + 250, row_top + 32, true);

    draw_set_color(c_white);
    draw_text(col1_x + 14, row_top + 9, string_upper(primary_list[i]));
}

for (var j = 0; j < array_length(secondary_list); j++) {
    var row_top_2 = list_top + j * row_h;
    var selected_2 = (j == secondary_index);
    var active_2 = (active_column == 1);

    draw_set_color(selected_2 ? make_color_rgb(42, 58, 108) : make_color_rgb(24, 28, 42));
    draw_rectangle(col2_x, row_top_2, col2_x + 250, row_top_2 + 32, false);

    draw_set_color((selected_2 && active_2) ? make_color_rgb(255, 100, 100) : make_color_rgb(180, 190, 255));
    draw_rectangle(col2_x, row_top_2, col2_x + 250, row_top_2 + 32, true);

    draw_set_color(c_white);
    draw_text(col2_x + 14, row_top_2 + 9, string_upper(secondary_list[j]));
}

var back_x = panel_x + 330;
var back_top = panel_top + 430;
var play_x = panel_x + 520;
var play_top = panel_top + 430;

// back button
draw_set_color(hover_back ? make_color_rgb(190, 55, 55) : make_color_rgb(135, 38, 38));
draw_rectangle(back_x, back_top, back_x + button_w, back_top + button_h, false);
draw_set_color(make_color_rgb(255, 115, 115));
draw_rectangle(back_x, back_top, back_x + button_w, back_top + button_h, true);
draw_set_color(c_white);
draw_text(back_x + 20, back_top + 12, "Back");

// play button
draw_set_color(hover_play ? make_color_rgb(70, 95, 185) : make_color_rgb(42, 58, 108));
draw_rectangle(play_x, play_top, play_x + button_w, play_top + button_h, false);
draw_set_color(make_color_rgb(190, 205, 255));
draw_rectangle(play_x, play_top, play_x + button_w, play_top + button_h, true);
draw_set_color(c_white);
draw_text(play_x + 20, play_top + 12, "Start Match");

draw_set_color(make_color_rgb(208, 212, 237));
draw_text(panel_x + 70, panel_top + 470, "TAB = switch column | UP/DOWN = choose | ENTER = start | ESC = back");