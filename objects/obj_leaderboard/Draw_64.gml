// Reset draw state
draw_set_font(-1);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_color(c_white);
draw_set_alpha(1);

/// Draw_64 (Draw GUI) — obj_leaderboard

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
var panel_h = 520;
var panel_x = (gui_w - panel_w) / 2;
var panel_y = (gui_h - panel_h) / 2;

draw_set_alpha(0.90);
draw_set_color(make_color_rgb(18, 20, 30));
draw_rectangle(panel_x, panel_y, panel_x + panel_w, panel_y + panel_h, false);
draw_set_alpha(1);
draw_set_color(make_color_rgb(90, 110, 185));
draw_rectangle(panel_x, panel_y, panel_x + panel_w, panel_y + panel_h, true);

// Title
var pulse = 0.5 + 0.5 * sin(current_time / 260);
draw_set_color(make_color_rgb(lerp(185, 255, pulse), lerp(185, 225, pulse), 255));
draw_set_halign(fa_center);
draw_text(panel_x + panel_w / 2, panel_y + 20, "LEADERBOARD");

// Subtitle
draw_set_color(make_color_rgb(208, 212, 237));
draw_text(panel_x + panel_w / 2, panel_y + 48, "Wins  /  Kills  /  Deaths");
draw_set_halign(fa_left);

// Column positions
var table_x   = panel_x + 30;
var table_y   = panel_y + 90;
var table_w   = panel_w - 60;
var row_h     = 34;
var col_rank  = table_x + 15;
var col_name  = table_x + 70;
var col_wins  = table_x + 420;
var col_kills = table_x + 540;
var col_deaths = table_x + 660;

// Header row
draw_set_color(make_color_rgb(44, 64, 119));
draw_rectangle(table_x, table_y, table_x + table_w, table_y + row_h, false);
draw_set_color(c_yellow);
draw_text(col_rank,   table_y + 9, "#");
draw_text(col_name,   table_y + 9, "USERNAME");
draw_text(col_wins,   table_y + 9, "WINS");
draw_text(col_kills,  table_y + 9, "KILLS");
draw_text(col_deaths, table_y + 9, "DEATHS");

// Data rows
if (array_length(leaderboard_data) == 0) {
    draw_set_color(c_ltgray);
    draw_set_halign(fa_center);
    draw_text(panel_x + panel_w / 2, table_y + row_h + 20, status_text);
    draw_set_halign(fa_left);
} else {
    var max_rows = 10;
    for (var i = 0; i < min(array_length(leaderboard_data), max_rows); i++) {
        var row_y   = table_y + row_h + i * row_h;
        var entry   = leaderboard_data[i];
        var is_me   = variable_global_exists("username") && (entry.username == global.username);

        // Row background
        if (is_me) {
            draw_set_color(make_color_rgb(35, 65, 35));
        } else if (i mod 2 == 0) {
            draw_set_color(make_color_rgb(28, 32, 48));
        } else {
            draw_set_color(make_color_rgb(22, 26, 40));
        }
        draw_rectangle(table_x, row_y, table_x + table_w, row_y + row_h, false);

        // Rank medal color
        var rank_col = c_white;
        if      (i == 0) rank_col = make_color_rgb(255, 215, 0);   // gold
        else if (i == 1) rank_col = make_color_rgb(192, 192, 192); // silver
        else if (i == 2) rank_col = make_color_rgb(205, 127, 50);  // bronze

        draw_set_color(rank_col);
        draw_text(col_rank, row_y + 9, string(i + 1));

        // Username — highlight if it's the logged-in player
        draw_set_color(is_me ? c_lime : c_white);
        var _name = variable_struct_exists(entry, "username") ? entry.username : "Unknown";
        if (is_me) _name += "  (you)";
        draw_text(col_name, row_y + 9, _name);

        // Stats
        draw_set_color(c_white);
        var _wins   = variable_struct_exists(entry, "wins")   ? entry.wins   : 0;
        var _kills  = variable_struct_exists(entry, "kills")  ? entry.kills  : 0;
        var _deaths = variable_struct_exists(entry, "deaths") ? entry.deaths : 0;

        draw_set_color(make_color_rgb(100, 220, 100));
        draw_text(col_wins,  row_y + 9, string(_wins));
        draw_set_color(make_color_rgb(220, 180, 80));
        draw_text(col_kills, row_y + 9, string(_kills));
        draw_set_color(make_color_rgb(220, 100, 100));
        draw_text(col_deaths, row_y + 9, string(_deaths));
    }
}

// Back button
function draw_lb_button(_x, _y, _w, _h, _label, _hov) {
    draw_set_color(_hov ? make_color_rgb(70, 95, 185) : make_color_rgb(42, 58, 108));
    draw_rectangle(_x, _y, _x + _w, _y + _h, false);
    draw_set_color(_hov ? make_color_rgb(255, 100, 100) : make_color_rgb(190, 205, 255));
    draw_rectangle(_x, _y, _x + _w, _y + _h, true);
    draw_set_color(c_white);
    draw_set_halign(fa_center);
    draw_text(_x + _w / 2, _y + 12, _label);
    draw_set_halign(fa_left);
}

var back_x    = panel_x + 30;
var back_y    = panel_y + panel_h - 55;
var refresh_x = panel_x + 185;
var refresh_y = back_y;

draw_lb_button(back_x,    back_y,    button_w, button_h, "Back",    hover_back);
draw_lb_button(refresh_x, refresh_y, button_w, button_h, "Refresh", hover_refresh);

// Footer
draw_set_color(make_color_rgb(130, 140, 170));
draw_text(panel_x + 350, panel_y + panel_h - 38, status_text + "   |   ESC = back");
