/// CleanUp_0 — oLobby
/// Fires when the room changes or the game closes.
/// Sends a disconnect packet so the server removes this player immediately
/// rather than waiting for the 5-second timeout.

if (socket >= 0) {
    var _buf = buffer_create(1, buffer_fixed, 1);
    buffer_write(_buf, buffer_u8, 9);  // type 9 = disconnect
    network_send_udp_raw(socket, global.ip_address, global.port, _buf, 1);
    buffer_delete(_buf);
    network_destroy(socket);
    socket = -1;
}
