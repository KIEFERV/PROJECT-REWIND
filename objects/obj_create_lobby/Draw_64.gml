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
var panel_w = 520;
var panel_h = 350;
var panel_x = (gui_w - panel_w) / 2;
var panel_y = (gui_h - panel_h) / 2;

draw_set_alpha(0.92);
draw_set_color(make_color_rgb(18, 20, 28));
draw_rectangle(panel_x, panel_y, panel_x + panel_w, panel_y + panel_h, false);

// Border
draw_set_color(make_color_rgb(80, 100, 170));
draw_rectangle(panel_x, panel_y, panel_x + panel_w, panel_y + panel_h, true);
draw_set_alpha(1);

// Title
draw_set_color(c_white);
draw_text(panel_x + 170, panel_y + 20, "Create Lobby");

// Helper for visible text
function fit_text(_s, _max) {
    if (string_length(_s) <= _max) return _s;
    return string_copy(_s, string_length(_s) - (_max - 1), _max);
}

// Field drawer
function draw_field(_panel_x, _panel_w, _label, _value, _y, _active) {
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
    var shown = fit_text(string(_value), 34);
    draw_text(_panel_x + 40, _y + 10, shown);
}

// Fields
draw_field(panel_x, panel_w, "Lobby Name", name_text, panel_y + 70, active_field == 0);
draw_field(panel_x, panel_w, "Description", description_text, panel_y + 130, active_field == 1);
draw_field(panel_x, panel_w, "Max Participants", string(max_participants), panel_y + 190, active_field == 2);

// Private/public toggle
draw_set_color(make_color_rgb(208, 212, 237));
draw_text(panel_x + 30, panel_y + 245, "P = Toggle Private/Public");
draw_text(panel_x + 30, panel_y + 270, "Current Type: " + (is_private ? "Private" : "Public"));

// Instructions
draw_set_color(make_color_rgb(208, 212, 237));
draw_text(panel_x + 30, panel_y + 300, "TAB = switch | LEFT/RIGHT = size | ENTER = create | ESC = back");

// Status
draw_set_color(c_white);
draw_text(panel_x + 30, panel_y + 325, status_text);