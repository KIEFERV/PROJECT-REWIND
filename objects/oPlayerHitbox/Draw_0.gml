// Draw your own sprite (only if alive)
if (global.player_alive) {
    draw_sprite_ext(sPlayerModel, image_index, x, y,
                    1, 1,
                    player_look_dir,
                    c_white, 1);
}

// Draw other players (only if HP > 0)
var pid = ds_map_find_first(other_players);
repeat (ds_map_size(other_players)) {
    var entry = other_players[? pid];
    if (!is_undefined(entry)) {
        var ox      = entry[0];
        var oy      = entry[1];
        var ohp     = entry[2];
        var oanim   = entry[3];
        var ofacing = entry[4];
        var otime_phase = entry[5];

    // Only draw if alive and in the same time phase
    if (ohp > 0 && otime_phase == oPlayerHitbox.time_phase) {
            draw_sprite_ext(sPlayerEnemyModel, oanim, ox, oy,
                    1, 1,
                    ofacing,
                    c_white, 1);

            // Health bar above head — clamp to prevent overflow
            var _hp_ratio = clamp(ohp / max_hp, 0, 1);
            draw_set_color(c_red);
            draw_rectangle(ox - 16, oy - 28, ox + 16, oy - 22, false);
            draw_set_color(c_lime);
            draw_rectangle(ox - 16, oy - 28, ox - 16 + (32 * _hp_ratio), oy - 22, false);
            draw_set_color(c_white);
        }
    }
    pid = ds_map_find_next(other_players, pid);
}

if (debug_menu = true) {}

if (show_GUI = true) {
    if (reloading = true) {
        draw_circular_bar(mouse_x, mouse_y, reload_time - reload_timer, reload_time, c_white, 16, 1, 3);
    } else {
        draw_sprite_ext(sCrosshair, 0, mouse_x, mouse_y, 1, 1, 0, c_white, 1);
    }
}


// ── Knife swing cone flash ────────────────────────────────────────────────
if (weapon_type == "melee" && knife_swing_timer > 0) {
    var _segments = 8;
    var _alpha    = knife_swing_timer / 12;

    draw_set_alpha(_alpha * 0.55);
    draw_set_color(make_color_rgb(255, 220, 50));

    for (var _s = 0; _s < _segments; _s++) {
        var _ang1 = player_look_dir - knife_arc / 2 + (_s / _segments) * knife_arc;
        var _ang2 = player_look_dir - knife_arc / 2 + ((_s + 1) / _segments) * knife_arc;
        var _x1 = x + lengthdir_x(knife_range, _ang1);
        var _y1 = y + lengthdir_y(knife_range, _ang1);
        var _x2 = x + lengthdir_x(knife_range, _ang2);
        var _y2 = y + lengthdir_y(knife_range, _ang2);
        draw_triangle(x, y, _x1, _y1, _x2, _y2, false);
    }

    draw_set_alpha(_alpha);
    draw_set_color(c_yellow);
    var _edge_l_x = x + lengthdir_x(knife_range, player_look_dir - knife_arc / 2);
    var _edge_l_y = y + lengthdir_y(knife_range, player_look_dir - knife_arc / 2);
    var _edge_r_x = x + lengthdir_x(knife_range, player_look_dir + knife_arc / 2);
    var _edge_r_y = y + lengthdir_y(knife_range, player_look_dir + knife_arc / 2);
    draw_line(x, y, _edge_l_x, _edge_l_y);
    draw_line(x, y, _edge_r_x, _edge_r_y);

    draw_set_alpha(1);
    draw_set_color(c_white);
	
	}