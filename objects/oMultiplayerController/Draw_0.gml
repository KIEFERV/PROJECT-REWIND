draw_self();  // draws your own sprite as normal

var pid = ds_map_find_first(other_players);
repeat (ds_map_size(other_players)) {
    var entry = other_players[? pid];
    draw_sprite(oPlayerModel, -1, oPlayerModel.x, oPlayerModel.y);
    draw_text(entry[0], entry[1] - 24, pid);
    pid = ds_map_find_next(other_players, pid);
}