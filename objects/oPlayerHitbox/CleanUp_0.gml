/// CleanUp_0 — oPlayerHitbox
/// Sends disconnect when leaving the game room or closing the game.

if (global.socket >= 0) {
    var _buf = buffer_create(1, buffer_fixed, 1);
    buffer_write(_buf, buffer_u8, 9);  // type 9 = disconnect
    network_send_udp_raw(global.socket, global.ip_address, global.port, _buf, 1);
    buffer_delete(_buf);
    network_destroy(global.socket);
    global.socket = -1;
}

