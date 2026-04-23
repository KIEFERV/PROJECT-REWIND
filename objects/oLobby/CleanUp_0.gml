/// CleanUp_0 — oLobby
/// Fires when the room changes or the game closes.
/// Only sends a disconnect if we are NOT transitioning into the match room.
/// When starting a match, global.socket is handed off to oPlayerHitbox
/// and set to -1 here so we know not to disconnect.

if (socket >= 0 && global.socket != socket) {
    // socket wasn't handed off — we're leaving without starting a match
    var _buf = buffer_create(1, buffer_fixed, 1);
    buffer_write(_buf, buffer_u8, 9);  // type 9 = disconnect
    network_send_udp_raw(socket, global.ip_address, global.port, _buf, 1);
    buffer_delete(_buf);
    network_destroy(socket);
    socket = -1;
}
