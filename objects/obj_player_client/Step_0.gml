x= mouse_x;
y = mouse_y;

ds_map_add(data, "x", mouse_x);
ds_map_add(data, "y", mouse_y);
dataJson = json_encode(data);
ds_map_clear(data);

buffer_seek(player_buffer, buffer_seek_start, 0); 
buffer_write(player_buffer, buffer_text, dataJson); //send locational data of player
network_send_udp_raw(client, "127.0.0.1", 54000, player_buffer, buffer_tell(player_buffer));