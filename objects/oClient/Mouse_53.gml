x = oTestPlayer.x;
y = oTestPlayer.y;

ds_map_add(data, "x", oTestPlayer.x);//sends test player locational data to server
ds_map_add(data, "y", oTestPlayer.y);
ds_map_add(data, "id", id); //send player id
dataJson = json_encode(data);
ds_map_clear(data);

buffer_seek(player_buffer, buffer_seek_start,0);
buffer_write(player_buffer, buffer_text, dataJson);
network_send_udp_raw(client, "127.0.0.1",54000, player_buffer, buffer_tell(player_buffer));
