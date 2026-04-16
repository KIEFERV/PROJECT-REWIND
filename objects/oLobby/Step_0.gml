// Only host can start, only after we know our pid
if (is_host && keyboard_check_pressed(vk_space)) {
    var buf = buffer_create(4, buffer_grow, 1);
    buffer_seek(buf, buffer_seek_start, 0);
    buffer_write(buf, buffer_u8, 7);  // type 7 = start match request
    network_send_udp_raw(socket, global.ip_address, 7777, buf, buffer_tell(buf));
    buffer_delete(buf);
    status_msg = "Starting...";
}