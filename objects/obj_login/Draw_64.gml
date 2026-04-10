var gui_w = display_get_gui_width();
var gui_h = display_get_gui_height();

// Background
draw_sprite_stretched(spr_time_bg, 0, 0, 0, gui_w, gui_h);

// Dark overlay
draw_set_alpha(0.55);
draw_set_color(make_color_rgb(10, 12, 18));
draw_rectangle(0, 0, gui_w, gui_h, false);
draw_set_alpha(1);

// Panel
var panel_w = 440;
var panel_h = 320;
var panel_x = (gui_w - panel_w) / 2;
var panel_y = (gui_h - panel_h) / 2;


draw_set_alpha(0.92);
draw_set_color(make_color_rgb(18, 20, 28));
draw_rectangle(panel_x, panel_y, panel_x + panel_w, panel_y + panel_h, false);

// Border
draw_set_color(make_color_rgb(80, 100, 170));
draw_rectangle(panel_x, panel_y, panel_x + panel_w, panel_y + panel_h, true);
draw_set_alpha(1);

// Title glow
var pulse = 0.5 + 0.5 * sin(current_time / 300);
var r = lerp(180, 255, pulse);
var g = lerp(180, 220, pulse);
var b = 255;

draw_set_color(make_color_rgb(r, g, b));
draw_text(panel_x + 145, panel_y + 20, "Project Rewind");

// Subtitle
draw_set_color(make_color_rgb(208, 212, 237));
draw_text(panel_x + 168, panel_y + 50, "Login");

// helper
function fit_text(_s, _max) {
    if (string_length(_s) <= _max) return _s;
    return string_copy(_s, string_length(_s) - (_max - 1), _max);
}

// field drawer
function draw_login_field(_panel_x, _panel_w, _label, _value, _masked, _y, _active) {
    draw_set_color(c_white);
    draw_text(_panel_x + 30, _y - 20, _label);

    if (_active) {
        draw_set_alpha(0.20);
        draw_set_color(make_color_rgb(255, 80, 80));
        draw_rectangle(_panel_x + 25, _y - 5, _panel_x + _panel_w - 25, _y + 40, false);
        draw_set_alpha(1);
    }

    draw_set_color(_active ? make_color_rgb(249, 37, 37) : c_white);
    draw_rectangle(_panel_x + 30, _y, _panel_x + _panel_w - 30, _y + 35, true);

    draw_set_color(c_white);
    var shown = _masked ? string_repeat("*", string_length(_value)) : _value;
    shown = fit_text(shown, 26);
    draw_text(_panel_x + 40, _y + 10, shown);
}

// fields
var user_y = panel_y + 95;
var pass_y = panel_y + 160;

draw_login_field(panel_x, panel_w, "Username", username_text, false, user_y, active_field == 0);
draw_login_field(panel_x, panel_w, "Password", password_text, true, pass_y, active_field == 1);

// button drawer
function draw_menu_button(_x, _y, _w, _h, _label, _hovered, _secondary) {
    var col_fill;
    var col_border;

    if (_secondary) {
        col_fill = _hovered ? make_color_rgb(70, 95, 180) : make_color_rgb(44, 64, 119);
        col_border = _hovered ? make_color_rgb(255, 90, 90) : make_color_rgb(180, 190, 255);
    } else {
        col_fill = _hovered ? make_color_rgb(210, 65, 65) : make_color_rgb(160, 45, 45);
        col_border = make_color_rgb(255, 110, 110);
    }

    if (_hovered) {
        draw_set_alpha(0.20);
        draw_set_color(make_color_rgb(255, 80, 80));
        draw_rectangle(_x - 4, _y - 4, _x + _w + 4, _y + _h + 4, false);
        draw_set_alpha(1);
    }

    draw_set_color(col_fill);
    draw_rectangle(_x, _y, _x + _w, _y + _h, false);

    draw_set_color(col_border);
    draw_rectangle(_x, _y, _x + _w, _y + _h, true);

    draw_set_color(c_white);
    draw_text(_x + 18, _y + 12, _label);
}

// buttons
var login_x = panel_x + 40;
var login_y = panel_y + 225;
var register_x = panel_x + 220;
var register_y = panel_y + 225;

draw_menu_button(login_x, login_y, button_w, button_h, "Login", hover_login, false);
draw_menu_button(register_x, register_y, button_w, button_h, "Register", hover_register, true);

// instructions
draw_set_color(make_color_rgb(208, 212, 237));
draw_text(panel_x + 30, panel_y + 280, "TAB = switch field | ENTER = login | Click Register to sign up");

// status
draw_set_color(c_white);
draw_text(panel_x + 30, panel_y + 300, status_text);