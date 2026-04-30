var gui_w = display_get_gui_width();
var gui_h = display_get_gui_height();

// Background
draw_sprite_stretched(spr_time_bg, 0, 0, 0, gui_w, gui_h);

// Dark overlay
draw_set_alpha(0.60);
draw_set_color(make_color_rgb(8, 10, 18));
draw_rectangle(0, 0, gui_w, gui_h, false);
draw_set_alpha(1);

// Floating particles
for (var i = 0; i < 20; i++) {
    var px = frac(sin(i * 91.73 + current_time * 0.0002) * 9999) * gui_w;
    var py = frac(cos(i * 47.11 + current_time * 0.00015) * 9999) * gui_h;
    draw_set_alpha(0.12);
    draw_set_color(make_color_rgb(180, 210, 255));
    draw_circle(px, py, 2, false);
}
draw_set_alpha(1);

// Main panel
var panel_w = 980;
var panel_h = 620;
var panel_x = (gui_w - panel_w) / 2;
var panel_y = (gui_h - panel_h) / 2;

draw_set_alpha(0.90);
draw_set_color(make_color_rgb(18, 20, 30));
draw_rectangle(panel_x, panel_y, panel_x + panel_w, panel_y + panel_h, false);
draw_set_alpha(1);

// Outer glow border
draw_set_alpha(0.18);
draw_set_color(make_color_rgb(100, 140, 255));
draw_rectangle(panel_x - 4, panel_y - 4, panel_x + panel_w + 4, panel_y + panel_h + 4, false);
draw_set_alpha(1);

// Main border
draw_set_color(make_color_rgb(90, 110, 185));
draw_rectangle(panel_x, panel_y, panel_x + panel_w, panel_y + panel_h, true);

// Divider
var divider_x = panel_x + 430;
draw_set_color(make_color_rgb(60, 75, 120));
draw_line(divider_x, panel_y + 30, divider_x, panel_y + panel_h - 30);

// Animated title glow
var pulse = 0.5 + 0.5 * sin(current_time / 260);
var r = lerp(185, 255, pulse);
var g = lerp(185, 225, pulse);
var b = 255;

draw_set_color(make_color_rgb(r, g, b));
draw_text(panel_x + 50, panel_y + 35, "PROJECT REWIND");

// Subtitle
draw_set_color(make_color_rgb(208, 212, 237));
draw_text(panel_x + 52, panel_y + 68, "Command Hub");

// Login state
var logged_in = (global.auth_token != "");
var uname = global.username;
if (uname == "") uname = "Guest";

var role_text = global.user_role;
if (role_text == "") role_text = "Offline";

// Welcome/user card
var card_x = panel_x + 455;
var card_y = panel_y + 40;
var card_w = 470;
var card_h = 130;

draw_set_alpha(0.75);
draw_set_color(make_color_rgb(28, 32, 48));
draw_rectangle(card_x, card_y, card_x + card_w, card_y + card_h, false);
draw_set_alpha(1);

draw_set_color(make_color_rgb(100, 125, 210));
draw_rectangle(card_x, card_y, card_x + card_w, card_y + card_h, true);

draw_set_color(c_white);
draw_text(card_x + 20, card_y + 18, "Welcome Back");

draw_set_color(make_color_rgb(220, 230, 255));
draw_text(card_x + 20, card_y + 48, "User: " + uname);
draw_text(card_x + 20, card_y + 74, "Role: " + role_text);
draw_text(card_x + 20, card_y + 100, "Logged In: " + string(logged_in));

// Info panel
var info_x = panel_x + 455;
var info_y = panel_y + 195;
var info_w = 470;
var info_h = 315;

draw_set_alpha(0.75);
draw_set_color(make_color_rgb(24, 28, 42));
draw_rectangle(info_x, info_y, info_x + info_w, info_y + info_h, false);
draw_set_alpha(1);

draw_set_color(make_color_rgb(85, 100, 170));
draw_rectangle(info_x, info_y, info_x + info_w, info_y + info_h, true);

draw_set_color(c_white);
draw_text(info_x + 20, info_y + 18, "System Status");

draw_set_color(make_color_rgb(208, 212, 237));
draw_text(info_x + 20, info_y + 55, "- Local server connection");
draw_text(info_x + 20, info_y + 82, "- Lobby management");
draw_text(info_x + 20, info_y + 109, "- Account access");
draw_text(info_x + 20, info_y + 136, "- Session controls");
draw_text(info_x + 20, info_y + 163, "- Leaderboard tracking");

draw_set_color(c_white);
draw_text(info_x + 20, info_y + 215, "Details");
draw_set_color(make_color_rgb(208, 212, 237));
draw_text(info_x + 20, info_y + 248, status_text);

// Footer help
draw_set_color(make_color_rgb(208, 212, 237));
if (logged_in) {
    draw_text(info_x + 20, panel_y + panel_h - 35, "ENTER Practice | P Play Online | T Leaderboard | Logout available");
} else {
    draw_text(info_x + 20, panel_y + panel_h - 35, "ENTER Practice | P Play Online | L Login | R Register | T Leaderboard");
}

// Button drawer
function draw_hub_button(_x, _y, _w, _h, _label, _hovered, _danger, _primary, _disabled) {
    var fill_col;
    var border_col;
    var glow_col;

    if (_disabled) {
        fill_col = make_color_rgb(45, 48, 60);
        border_col = make_color_rgb(95, 100, 120);
        glow_col = make_color_rgb(95, 100, 120);
    }
    else if (_primary) {
        fill_col = _hovered ? make_color_rgb(255, 190, 80) : make_color_rgb(200, 150, 60);
        border_col = make_color_rgb(255, 230, 120);
        glow_col = make_color_rgb(255, 200, 90);
    }
    else if (_danger) {
        fill_col = _hovered ? make_color_rgb(190, 55, 55) : make_color_rgb(135, 38, 38);
        border_col = make_color_rgb(255, 115, 115);
        glow_col = make_color_rgb(255, 90, 90);
    }
    else {
        fill_col = _hovered ? make_color_rgb(70, 95, 185) : make_color_rgb(42, 58, 108);
        border_col = _hovered ? make_color_rgb(255, 100, 100) : make_color_rgb(190, 205, 255);
        glow_col = make_color_rgb(255, 90, 90);
    }

    if (_hovered && !_disabled) {
        draw_set_alpha(0.20);
        draw_set_color(glow_col);
        draw_rectangle(_x - 6, _y - 6, _x + _w + 6, _y + _h + 6, false);
        draw_set_alpha(1);
    }

    draw_set_color(fill_col);
    draw_rectangle(_x, _y, _x + _w, _y + _h, false);

    draw_set_color(border_col);
    draw_rectangle(_x, _y, _x + _w, _y + _h, true);

    if (_disabled) {
        draw_set_color(make_color_rgb(160, 165, 180));
    } else {
        draw_set_color(c_white);
    }

    draw_text(_x + 22, _y + 15, _label);
}

// Buttons
var left_x  = panel_x + 50;
var start_y = panel_y + 140;
var vis_y   = start_y;

for (var i = 0; i < array_length(menu_buttons); i++) {
    var btn = menu_buttons[i];

    // Skip login/register when logged in
    var hidden = variable_struct_exists(btn, "hide_when_logged_in")
                 && btn.hide_when_logged_in && logged_in;
    if (hidden) continue;

    var is_logout  = (btn.action == "logout");
    var is_primary = btn.primary;
    var is_disabled = (btn.requires_login && !logged_in);

    draw_hub_button(left_x, vis_y, button_w, button_h,
        btn.label, i == hover_index, is_logout, is_primary, is_disabled);
    vis_y += button_h + button_gap;
}