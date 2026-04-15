/// @description CleanUp

// Graceful disconnect — notify rendezvous server
var buf = buffer_create(1, buffer_fixed, 1);
buffer_write(buf, buffer_u8, 9);
network_send_udp_raw(socket, RENDEZVOUS_IP, RENDEZVOUS_PORT, buf, 1);

// Also notify every peer directly so they can clean up their state immediately
var _pid = ds_map_find_first(peer_addrs);
while (!is_undefined(_pid)) {
    var _addr = ds_map_find_value(peer_addrs, _pid);
    network_send_udp_raw(socket, _addr[0], _addr[1], buf, 1);
    _pid = ds_map_find_next(peer_addrs, _pid);
}

buffer_delete(buf);
ds_map_destroy(other_players);
ds_map_destroy(peer_addrs);
network_destroy(socket);

event_inherited();
