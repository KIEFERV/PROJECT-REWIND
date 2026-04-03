var gw = display_get_gui_width();
var gh = display_get_gui_height();

draw_sprite_stretched(spr_time_bg,0,0,0,gw,gh);

// dark overlay for readability
draw_set_alpha(0.55);
draw_set_color(make_color_rgb(10,12,18));
draw_rectangle(0,0,gw,gh,false);
draw_set_alpha(1);

draw_set_color(c_white);
draw_text(gw/2 - 80, gh/2 - 60, "Main Menu");

draw_text(gw/2 - 140, gh/2 - 10, "R - Register new account");
draw_text(gw/2 - 140, gh/2 + 20, "C - Create Lobby");
draw_text(gw/2 - 140, gh/2 + 50, "B - Browse Lobbies");
draw_text(gw/2 - 140, gh/2 + 80, "L - Logout");