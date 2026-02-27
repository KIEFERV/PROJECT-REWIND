buffer_seek(buffer,buffer_seek_start, 0);
buffer_write(buffer, buffer_text, "test");
network_send_udp_raw(socket, ip, port, buffer, 100);