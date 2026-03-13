var gui_w = display_get_gui_width();
var gui_h = display_get_gui_height();

// Draw the background stretched
draw_sprite_stretched(spr_time_bg, 0, 0, 0, gui_w, gui_h);

// dark overlay for readability
draw_set_alpha(0.55);
draw_set_color(make_color_rgb(10,12,18));
draw_rectangle(0,0,gui_w,gui_h,false);
draw_set_alpha(1);

// centered panel
var panel_w = 420;
var panel_h = 260;
var panel_x = (gui_w - panel_w) / 2;
var panel_y = (gui_h - panel_h) / 2;

draw_set_alpha(0.92);
draw_set_color(make_color_rgb(18,20,28));
draw_rectangle(panel_x, panel_y, panel_x + panel_w, panel_y + panel_h, false);

// subtle border
draw_set_color(make_color_rgb(80,100,170));
draw_rectangle(panel_x, panel_y, panel_x + panel_w, panel_y + panel_h, true);

draw_set_alpha(1);

// title
draw_set_color(c_white);
draw_text(panel_x + 170, panel_y + 20, "Login");

// username box
var user_y = panel_y + 70;
draw_set_color(c_white);
draw_text(panel_x + 30, user_y - 20, "Username");

draw_set_color(active_field == 0 ? make_color_rgb(249, 37, 37) : c_white);
draw_rectangle(panel_x + 30, user_y, panel_x + 390, user_y + 35, true);
draw_set_color(c_white);
draw_text(panel_x + 40, user_y + 10, username_text);

// password box
var pass_y = panel_y + 130;
draw_set_color(c_white);
draw_text(panel_x + 30, pass_y - 20, "Password");

draw_set_color(active_field == 1 ? make_color_rgb(249, 37, 37) : c_white);
draw_rectangle(panel_x + 30, pass_y, panel_x + 390, pass_y + 35, true);
draw_set_color(c_white);
draw_text(panel_x + 40, pass_y + 10, string_repeat("*", string_length(password_text)));

// instructions
draw_set_color(make_color_rgb(208, 212, 237));
draw_text(panel_x + 30, panel_y + 185, "Press TAB to switch fields.");
draw_text(panel_x + 30, panel_y + 205, "Press ENTER to login.");

// status
draw_set_color(c_white);
draw_text(panel_x + 30, panel_y + 230, status_text);