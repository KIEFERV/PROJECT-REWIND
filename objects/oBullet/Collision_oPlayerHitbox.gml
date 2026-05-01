/// oBullet — Collision with oPlayerHitbox

// ── Time phase check — bullets only hit players in the same phase ─────────
if (time_phase != other.time_phase) exit;

// ── Skip if this is our own bullet ───────────────────────────────────────
if (other.id == owner_id) exit;

// ── Skip if already dead ─────────────────────────────────────────────────
if (other.dead_state) exit;

// ── Ghost bullets don't deal damage ──────────────────────────────────────
if (is_ghost) exit;

other.hitpoints -= damage;

if (other.hitpoints <= 0) {
    other.hitpoints     = 0;
    other.dead_state    = true;
    other.visible       = false;
    global.player_alive = false;

    // Victim sends kill report to server
    var _buf = buffer_create(3, buffer_fixed, 1);
    buffer_write(_buf, buffer_u8,  11);           // PKT_KILL_REPORT
    buffer_write(_buf, buffer_u16, other.my_pid); // victim pid
    network_send_udp_raw(global.socket, global.ip_address, global.port, _buf, buffer_tell(_buf));
    buffer_delete(_buf);

    show_debug_message("I was killed (pid=" + string(other.my_pid) + ") — sent kill report");
}

instance_destroy();
