// Step Event
var buf = buffer_create(64, buffer_fixed, 1);
buffer_seek(buf, buffer_seek_start, 0);
buffer_write(buf, buffer_string, string(x) + "," + string(y));
network_send_udp_raw(socket, "127.0.0.1", 7777, buf, buffer_tell(buf));
buffer_delete(buf);