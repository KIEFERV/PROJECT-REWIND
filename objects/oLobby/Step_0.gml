/// Step_0 — oLobby

// ── Join retry ────────────────────────────────────────────────────────────
// Resend type-10 every 2 seconds until we receive our pid from the server.
// This handles the case where the initial join packet was lost, or the server
// was mid-reset when we first connected (e.g. returning after a match).
if (!variable_instance_exists(id, "join_retry_timer")) join_retry_timer = 0;
if (my_pid == 0) {
    join_retry_timer++;
    if (join_retry_timer >= game_get_speed(gamespeed_fps) * 2) {
        join_retry_timer = 0;
        var _rbuf = buffer_create(1, buffer_fixed, 1);
        buffer_write(_rbuf, buffer_u8, 10);
        network_send_udp_raw(socket, global.ip_address, global.port,
                             _rbuf, buffer_tell(_rbuf));
        buffer_delete(_rbuf);
        show_debug_message("oLobby: retrying join request...");
    }
}

// ── Keepalive ─────────────────────────────────────────────────────────────
// Send a type-12 keepalive every 2 seconds once registered.
if (!variable_instance_exists(id, "keepalive_timer")) keepalive_timer = 0;
if (my_pid > 0) {
    keepalive_timer++;
    if (keepalive_timer >= game_get_speed(gamespeed_fps) * 2) {
        keepalive_timer = 0;
        var _buf = buffer_create(1, buffer_fixed, 1);
        buffer_write(_buf, buffer_u8, 12);
        network_send_udp_raw(socket, global.ip_address, global.port,
                             _buf, buffer_tell(_buf));
        buffer_delete(_buf);
    }
}

// ── Host start ────────────────────────────────────────────────────────────
if (is_host && my_pid > 0 && keyboard_check_pressed(vk_space)) {
    var buf = buffer_create(1, buffer_fixed, 1);
    buffer_write(buf, buffer_u8, 7);
    network_send_udp_raw(socket, global.ip_address, global.port,
                         buf, buffer_tell(buf));
    buffer_delete(buf);
    status_msg = "Starting...";
}
