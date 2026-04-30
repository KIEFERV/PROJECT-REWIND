var gui_w = display_get_gui_width();
var gui_h = display_get_gui_height();

draw_sprite_stretched(spr_time_bg, 0, 0, 0, gui_w, gui_h);

draw_set_alpha(0.60);
draw_set_color(make_color_rgb(8, 10, 18));
draw_rectangle(0, 0, gui_w, gui_h, false);
draw_set_alpha(1);

var panel_w   = 860;
var panel_h   = 600;
var panel_x   = (gui_w - panel_w) / 2;
var panel_top = (gui_h - panel_h) / 2;

draw_set_alpha(0.92);
draw_set_color(make_color_rgb(18, 20, 30));
draw_rectangle(panel_x, panel_top, panel_x + panel_w, panel_top + panel_h, false);
draw_set_alpha(1);
draw_set_color(make_color_rgb(90, 110, 185));
draw_rectangle(panel_x, panel_top, panel_x + panel_w, panel_top + panel_h, true);

draw_set_color(c_white);
draw_set_halign(fa_center);
draw_text(panel_x + panel_w / 2, panel_top + 25, "LOADOUT");
draw_set_color(make_color_rgb(208, 212, 237));
draw_text(panel_x + panel_w / 2, panel_top + 55, "Choose your weapons before entering the match");
draw_set_halign(fa_left);

var col1_x   = panel_x + 70;
var col2_x   = panel_x + 450;
var list_top = panel_top + 120;
var row_h    = 42;

// Column headers
draw_set_color(make_color_rgb(255, 200, 80));
draw_text(col1_x, list_top - 35, "PRIMARY  [1]");
draw_text(col2_x, list_top - 35, "SECONDARY  [2]");

// Primary list
for (var i = 0; i < array_length(primary_list); i++) {
    var row_top  = list_top + i * row_h;
    var selected = (i == primary_index);
    var active   = (active_column == 0);

    draw_set_color(selected ? make_color_rgb(42, 58, 108) : make_color_rgb(24, 28, 42));
    draw_rectangle(col1_x, row_top, col1_x + 310, row_top + 32, false);
    draw_set_color((selected && active) ? make_color_rgb(255, 100, 100) : make_color_rgb(180, 190, 255));
    draw_rectangle(col1_x, row_top, col1_x + 310, row_top + 32, true);
    draw_set_color(c_white);
    draw_text(col1_x + 14, row_top + 9, string_upper(primary_list[i]));
}

// Secondary list
for (var j = 0; j < array_length(secondary_list); j++) {
    var row_top2  = list_top + j * row_h;
    var selected2 = (j == secondary_index);
    var active2   = (active_column == 1);

    draw_set_color(selected2 ? make_color_rgb(42, 58, 108) : make_color_rgb(24, 28, 42));
    draw_rectangle(col2_x, row_top2, col2_x + 310, row_top2 + 32, false);
    draw_set_color((selected2 && active2) ? make_color_rgb(255, 100, 100) : make_color_rgb(180, 190, 255));
    draw_rectangle(col2_x, row_top2, col2_x + 310, row_top2 + 32, true);
    draw_set_color(c_white);
    draw_text(col2_x + 14, row_top2 + 9, string_upper(secondary_list[j]));
}

// Description boxes — anchored below primary list (longest column)
var desc_y = list_top + 4 * row_h + 14;

draw_set_color(make_color_rgb(20, 26, 48));
draw_rectangle(col1_x, desc_y, col1_x + 310, desc_y + 50, false);
draw_set_color(make_color_rgb(90, 110, 185));
draw_rectangle(col1_x, desc_y, col1_x + 310, desc_y + 50, true);
draw_set_color(make_color_rgb(170, 200, 255));
draw_text_ext(col1_x + 10, desc_y + 8, primary_info[primary_index], -1, 290);

draw_set_color(make_color_rgb(20, 26, 48));
draw_rectangle(col2_x, desc_y, col2_x + 310, desc_y + 50, false);
draw_set_color(make_color_rgb(90, 110, 185));
draw_rectangle(col2_x, desc_y, col2_x + 310, desc_y + 50, true);
draw_set_color(make_color_rgb(170, 200, 255));
draw_text_ext(col2_x + 10, desc_y + 8, secondary_info[secondary_index], -1, 290);

// Buttons
var back_x   = panel_x + 330;
var back_top = panel_top + 520;
var play_x   = panel_x + 520;
var play_top = panel_top + 520;

draw_set_color(hover_back ? make_color_rgb(190, 55, 55) : make_color_rgb(135, 38, 38));
draw_rectangle(back_x, back_top, back_x + button_w, back_top + button_h, false);
draw_set_color(make_color_rgb(255, 115, 115));
draw_rectangle(back_x, back_top, back_x + button_w, back_top + button_h, true);
draw_set_color(c_white);
draw_set_halign(fa_center);
draw_text(back_x + button_w / 2, back_top + 12, "Back");

// Show "Locked In" state if waiting for other players
var _is_locked = variable_instance_exists(id, "locked_in") && locked_in;
draw_set_color(_is_locked ? make_color_rgb(20, 80, 20) : (hover_play ? make_color_rgb(70, 95, 185) : make_color_rgb(42, 58, 108)));
draw_rectangle(play_x, play_top, play_x + button_w, play_top + button_h, false);
draw_set_color(_is_locked ? c_lime : make_color_rgb(190, 205, 255));
draw_rectangle(play_x, play_top, play_x + button_w, play_top + button_h, true);
draw_set_color(c_white);
var _btn_label = _is_locked ? "Locked In!" : (global.socket >= 0 ? "Lock In" : "Start Match");
draw_text(play_x + button_w / 2, play_top + 12, _btn_label);

draw_set_halign(fa_center);
draw_set_color(make_color_rgb(208, 212, 237));
if (variable_instance_exists(id, "locked_in") && locked_in) {
    var _dots = string_repeat(".", (current_time div 400) mod 4);
    draw_set_color(c_lime);
    draw_text(panel_x + panel_w / 2, panel_top + 570, "Waiting for other players" + _dots);
} else {
    draw_text(panel_x + panel_w / 2, panel_top + 570,
        "TAB = switch column   |   UP/DOWN = choose   |   ENTER = lock in   |   ESC = back");
}
draw_set_halign(fa_left);
