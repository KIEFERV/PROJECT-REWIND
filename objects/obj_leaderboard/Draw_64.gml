var gui_w = display_get_gui_width();
var gui_h = display_get_gui_height();

// Background
draw_sprite_stretched(spr_time_bg, 0, 0, 0, gui_w, gui_h);

// Dark overlay
draw_set_alpha(0.60);
draw_set_color(make_color_rgb(8, 10, 18));
draw_rectangle(0, 0, gui_w, gui_h, false);
draw_set_alpha(1);

// Main panel
var panel_w = 820;
var panel_h = 500;
var panel_x = (gui_w - panel_w) / 2;
var panel_y = (gui_h - panel_h) / 2;

draw_set_alpha(0.90);
draw_set_color(make_color_rgb(18, 20, 30));
draw_rectangle(panel_x, panel_y, panel_x + panel_w, panel_y + panel_h, false);
draw_set_alpha(1);

// Border
draw_set_color(make_color_rgb(90, 110, 185));
draw_rectangle(panel_x, panel_y, panel_x + panel_w, panel_y + panel_h, true);

// Title glow
var pulse = 0.5 + 0.5 * sin(current_time / 260);
var r = lerp(185, 255, pulse);
var g = lerp(185, 225, pulse);
var b = 255;

draw_set_color(make_color_rgb(r, g, b));
draw_text(panel_x + 300, panel_y + 20, "LEADERBOARD");

// Subtitle
draw_set_color(make_color_rgb(208, 212, 237));
draw_text(panel_x + 265, panel_y + 48, "Kills / Deaths / Time Played");

// Table header
var table_x = panel_x + 30;
var table_y = panel_y + 95;
var table_w = panel_w - 60;
var row_h = 32;

draw_set_color(make_color_rgb(44, 64, 119));
draw_rectangle(table_x, table_y, table_x + table_w, table_y + row_h, false);

draw_set_color(c_white);
draw_text(table_x + 20,  table_y + 8, "Rank");
draw_text(table_x + 90,  table_y + 8, "Username");
draw_text(table_x + 380, table_y + 8, "Kills");
draw_text(table_x + 480, table_y + 8, "Deaths");
draw_text(table_x + 590, table_y + 8, "Time Played");

// helper to format time
function format_time(_seconds) {
    var h = _seconds div 3600;
    var m = (_seconds mod 3600) div 60;
    var s = _seconds mod 60;

    var hh = string(h);
    var mm = string_format(m, 2, 0);
    var ss = string_format(s, 2, 0);

    if (m < 10) mm = "0" + string(m);
    if (s < 10) ss = "0" + string(s);

    return hh + ":" + mm + ":" + ss;
}

// draw rows
if (array_length(leaderboard_data) <= 0) {
    draw_set_color(c_white);
    draw_text(table_x + 20, table_y + 55, status_text);
} else {
    for (var i = 0; i < array_length(leaderboard_data); i++) {
        var row_y = table_y + row_h + i * row_h;

        // alternating row colors
        if (i mod 2 == 0) {
            draw_set_color(make_color_rgb(28, 32, 48));
        } else {
            draw_set_color(make_color_rgb(22, 26, 40));
        }

        draw_rectangle(table_x, row_y, table_x + table_w, row_y + row_h, false);

        draw_set_color(c_white);
        draw_text(table_x + 20, row_y + 8, string(i + 1));
        draw_text(table_x + 90, row_y + 8, string(leaderboard_data[i].username));
        draw_text(table_x + 380, row_y + 8, string(leaderboard_data[i].kills));
        draw_text(table_x + 480, row_y + 8, string(leaderboard_data[i].deaths));
        draw_text(table_x + 590, row_y + 8, format_time(leaderboard_data[i].time_played_seconds));
    }
}

// Back button
function draw_lb_button(_x, _y, _w, _h, _label, _hovered) {
    var fill_col = _hovered ? make_color_rgb(70, 95, 185) : make_color_rgb(42, 58, 108);
    var border_col = _hovered ? make_color_rgb(255, 100, 100) : make_color_rgb(190, 205, 255);

    if (_hovered) {
        draw_set_alpha(0.18);
        draw_set_color(make_color_rgb(255, 90, 90));
        draw_rectangle(_x - 4, _y - 4, _x + _w + 4, _y + _h + 4, false);
        draw_set_alpha(1);
    }

    draw_set_color(fill_col);
    draw_rectangle(_x, _y, _x + _w, _y + _h, false);

    draw_set_color(border_col);
    draw_rectangle(_x, _y, _x + _w, _y + _h, true);

    draw_set_color(c_white);
    draw_text(_x + 18, _y + 12, _label);
}

var back_x = panel_x + 30;
var back_y = panel_y + panel_h - 60;

draw_lb_button(back_x, back_y, button_w, button_h, "Back", hover_back);

// Footer status
draw_set_color(make_color_rgb(208, 212, 237));
draw_text(panel_x + 200, panel_y + panel_h - 35, status_text + "  |  ESC = back");