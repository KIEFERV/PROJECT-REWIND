// Draw your own sprite normally
draw_sprite_ext(sPlayerModel, image_index, x, y,
                1, 1,
                player_look_dir,
                c_white, 1);


// Draw other players
var pid = ds_map_find_first(other_players);
repeat (ds_map_size(other_players)) {
    var entry = other_players[? pid];
    if (!is_undefined(entry)) {
        var ox      = entry[0]; // x-pos
        var oy      = entry[1]; // y-pos
        var ohp     = entry[2]; // hp
        var oanim   = entry[3]; // sprite anim (currently unused)
        var ofacing = entry[4]; // look direction

        // Draw their sprite
        draw_sprite_ext(sPlayerEnemyModel, oanim, ox, oy,
                1, 1,
                ofacing,   
                c_white, 1);

        // Draw health bar above them
		// Do we want to keep this or use it for debug only?CAN BE SWAPPED TO draw_healthbar LATER
        draw_set_color(c_red);
        draw_rectangle(ox - 16, oy - 28, ox + 16, oy - 22, false);
        draw_set_color(c_lime);
        draw_rectangle(ox - 16, oy - 28, ox - 16 + (32 * (ohp/max_hp)), oy - 22, false);
        draw_set_color(c_white);
    }
    pid = ds_map_find_next(other_players, pid);
}

// Draw knife swing cone
if (weapon_type == "melee" && knife_swing_timer > 0) {
    var _knife_range = 60;
    var _knife_arc   = 90;
    var _segments    = 8;
    var _alpha       = knife_swing_timer / 12; // fade out as timer drops

    draw_set_alpha(_alpha * 0.55);
    draw_set_color(make_color_rgb(255, 220, 50));

    // Fan of triangles from player origin to arc edge
    for (var _s = 0; _s < _segments; _s++) {
        var _ang1 = image_angle - _knife_arc / 2 + (_s / _segments) * _knife_arc;
        var _ang2 = image_angle - _knife_arc / 2 + ((_s + 1) / _segments) * _knife_arc;

        var _x1 = x + lengthdir_x(_knife_range, _ang1);
        var _y1 = y + lengthdir_y(_knife_range, _ang1);
        var _x2 = x + lengthdir_x(_knife_range, _ang2);
        var _y2 = y + lengthdir_y(_knife_range, _ang2);

        draw_triangle(x, y, _x1, _y1, _x2, _y2, false);
    }

    // Outline
    draw_set_alpha(_alpha);
    draw_set_color(c_yellow);
    var _edge_l_x = x + lengthdir_x(_knife_range, image_angle - _knife_arc / 2);
    var _edge_l_y = y + lengthdir_y(_knife_range, image_angle - _knife_arc / 2);
    var _edge_r_x = x + lengthdir_x(_knife_range, image_angle + _knife_arc / 2);
    var _edge_r_y = y + lengthdir_y(_knife_range, image_angle + _knife_arc / 2);
    draw_line(x, y, _edge_l_x, _edge_l_y);
    draw_line(x, y, _edge_r_x, _edge_r_y);

    draw_set_alpha(1);
    draw_set_color(c_white);
}

if(debug_menu = true){
	
}
if (show_GUI = true){
	if (reloading = true){
		draw_circular_bar(mouse_x, mouse_y, reload_time - reload_timer , reload_time , c_white, 16, 1, 3);
		
	}else{
		draw_sprite_ext(sCrosshair, 0, mouse_x, mouse_y, 1, 1, 0, c_white, 1);
	}
}
