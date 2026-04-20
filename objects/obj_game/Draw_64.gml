draw_set_color(c_white);
draw_text(20, 20, "Kills: " + string(global.match_kills));
draw_text(20, 40, "Deaths: " + string(global.match_deaths));
draw_text(20, 60, "Time: " + string(global.match_time_seconds));
draw_text(20, 80, "Room Speed: " + string(room_speed));