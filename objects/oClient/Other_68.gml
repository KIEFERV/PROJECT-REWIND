/// Async - Networking Event
if (async_load[? "type"] == network_type_data) {
    var buff = async_load[? "buffer"];
    buffer_seek(buff, buffer_seek_start, 0);

    var other_x = buffer_read(buff, buffer_u16);
    var other_y = buffer_read(buff, buffer_u16);
    var other_sprite = buffer_read(buff, buffer_string);

    // Store or update other player's data
    // Example: draw them in Draw Event
    other_player_x = other_x;
    other_player_y = other_y;
    other_player_sprite = sPlayerModel;
}
