// Draw your own sprite normally
draw_self();

// Draw other players
var pid = ds_map_find_first(other_players);
repeat (ds_map_size(other_players)) {
    var entry = other_players[? pid];
    if (!is_undefined(entry)) {
        draw_rectangle(entry[0] - 16, entry[1] - 16, entry[0] + 16, entry[1] + 16, false);
        draw_text(entry[0], entry[1] - 24, pid);
    }
    pid = ds_map_find_next(other_players, pid);
}