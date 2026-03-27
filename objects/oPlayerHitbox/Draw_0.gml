if (show_death_screen)
{
    draw_set_color(c_black);
    draw_rectangle(0, 0, room_width, room_height, false); // full screen overlay
    draw_set_color(c_white);
    draw_text(room_width/2 - 50, room_height/2, "YOU DIED");
    draw_text(room_width/2 - 100, room_height/2 + 20, "Press SPACE to respawn");
}