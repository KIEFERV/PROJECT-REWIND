/// CleanUp_0 — oLobby

if (ds_exists(lobby_players, ds_type_map))
    ds_map_destroy(lobby_players);

if (socket >= 0 && global.socket != socket) {
    var _buf = buffer_create(1, buffer_fixed, 1);
    buffer_write(_buf, buffer_u8, 9);  // type 9 = disconnect
    network_send_udp_raw(socket, global.ip_address, global.port, _buf, 1);
    buffer_delete(_buf);
    network_destroy(socket);
    socket = -1;
}
