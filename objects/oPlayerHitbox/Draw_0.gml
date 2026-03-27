// Draw your own sprite normally
draw_self();

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

        // Draw their sprite (replace spr_player with your actual sprite name)
        draw_sprite_ext(sPlayerEnemyModel, oanim, ox, oy,
                1, 1,
                -ofacing + 90,   // negative because GML direction is counter-clockwise, draw rotation is clockwise
                c_white, 1);

        // Draw health bar above them
        draw_set_color(c_red);
        draw_rectangle(ox - 16, oy - 28, ox + 16, oy - 22, false);
        draw_set_color(c_lime);
        draw_rectangle(ox - 16, oy - 28, ox - 16 + (32 * (ohp/255)), oy - 22, false);
        draw_set_color(c_white);
    }
    pid = ds_map_find_next(other_players, pid);
}