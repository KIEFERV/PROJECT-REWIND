/// @description Alarm 0 — keepalive ping to rendezvous server
// Fires every 2 seconds to keep our NAT mapping alive on the server.

var _buf = buffer_create(1, buffer_fixed, 1);
buffer_write(_buf, buffer_u8, 0); // type 0 = register / keepalive
network_send_udp_raw(socket, RENDEZVOUS_IP, RENDEZVOUS_PORT, _buf, 1);
buffer_delete(_buf);

// Reschedule
alarm[0] = room_speed * 2;
