buffer_seek(player_buffer, buffer_seek_start, 0);
buffer_write(player_buffer, buffer_string, "testing message");
network_send_udp_raw(client, "127.0.0.1", 54000, player_buffer, 100);