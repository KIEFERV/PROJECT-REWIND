buffer_seek(player_buffer,buffer_seek_start, 0);
buffer_write(player_buffer, buffer_u16, oPlayerModel.x);
buffer_write(player_buffer, buffer_u16, oPlayerModel.y);
buffer_write(player_buffer,buffer_u16,oPlayerModel.image_angle)
buffer_write(player_buffer,buffer_string, sPlayerModel);

network_send_udp_raw(client,"127.0.0.1", 54000, player_buffer, buffer_tell(player_buffer));