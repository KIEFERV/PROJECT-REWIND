/// Step_0 — oLobby

// ── Keepalive ─────────────────────────────────────────────────────────────
// Send a type-12 keepalive to the game server every 2 seconds.
// Without this the server times out the player after 5 seconds of silence
// and re-assigns their pid when they next send a packet.
if (!variable_instance_exists(id, "keepalive_timer"))
    keepalive_timer = 0;

keepalive_timer++;
if (keepalive_timer >= game_get_speed(gamespeed_fps) * 2) {
    keepalive_timer = 0;
    var _buf = buffer_create(1, buffer_fixed, 1);
    buffer_write(_buf, buffer_u8, 12);  // type 12 = keepalive
    network_send_udp_raw(socket, global.ip_address, global.port,
                         _buf, buffer_tell(_buf));
    buffer_delete(_buf);
}

// ── Host start ────────────────────────────────────────────────────────────
// Only host can start, only after we know our pid
if (is_host && keyboard_check_pressed(vk_space)) {
    var buf = buffer_create(4, buffer_grow, 1);
    buffer_seek(buf, buffer_seek_start, 0);
    buffer_write(buf, buffer_u8, 7);  // type 7 = start match request
    network_send_udp_raw(socket, global.ip_address, global.port,
                         buf, buffer_tell(buf));
    buffer_delete(buf);
    status_msg = "Starting...";
}
