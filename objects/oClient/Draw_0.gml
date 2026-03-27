/// Draw Event
draw_sprite(sPlayerModel, 0, oPlayerModel.x, oPlayerModel.y);
if (variable_instance_exists(id, "other_player_sprite")) {
    draw_sprite(asset_get_index(other_player_sprite), 0, other_player_x, other_player_y);
}
