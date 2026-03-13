var p = instance_find(oPlayerHitbox, 0);
if (p != noone)
{
    // Weapon / ammo display
    var w = p.current_weapon;
    var margin = 24;
    var x_pos = display_get_gui_width() - margin;
    var y_pos = display_get_gui_height() - margin;

    draw_set_halign(fa_right);
    draw_set_valign(fa_middle);
    draw_set_color(c_white);

    draw_text(x_pos, y_pos, string(w.ammo_in_mag) + " / " + string(w.ammo_reserve));

    if (w.reloading)
        draw_text(x_pos, y_pos - 20, "RELOADING");

    // Death screen
    if (p.is_dead)
    {
        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        draw_set_color(c_red);
        draw_text(room_width/2, room_height/2 - 40, "YOU DIED");

        draw_set_color(c_white);
        draw_text(room_width/2, room_height/2 + 20, "Press SPACE to Respawn");
    }

    // Debug info
    if (debug_menu)
    {
        draw_set_color(c_yellow);
        draw_set_halign(fa_left);
        draw_set_valign(fa_middle);

        draw_text(50, 600, "player_hor_speed");
        draw_text(215, 600, string(player_hor_speed));

        draw_text(50, 615, "player_vert_speed");
        draw_text(215, 615, string(player_vert_speed));

        draw_text(50, 630, "listener distance");
        // draw_text(215, 630, string(dist)); // uncomment if 'dist' exists
    }

    draw_set_color(c_white);
}