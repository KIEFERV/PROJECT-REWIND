/// oBullet — Collision with oPlayerHitbox
/// This collision fires on whichever machine the bullet exists on.
/// For own bullets (owner_id = local oPlayerHitbox): skip self-damage.
/// For enemy bullets (owner_id = noone): damage local player, send kill report.

// Skip if this is our own bullet
if (other.id == owner_id) exit;

// Skip if already dead
if (other.dead_state) exit;

other.hitpoints -= damage;

if (other.hitpoints <= 0) {
    other.hitpoints     = 0;
    other.dead_state    = true;
    other.visible       = false;
    global.player_alive = false;

    // Victim sends the kill report — they know their own pid
    // killer_pid is 0 (server tracks kills by elimination, not by sender)
    var _buf = buffer_create(3, buffer_fixed, 1);
    buffer_write(_buf, buffer_u8,  11);           // PKT_KILL_REPORT
    buffer_write(_buf, buffer_u16, other.my_pid); // victim pid
    network_send_udp_raw(global.socket, global.ip_address, global.port, _buf, buffer_tell(_buf));
    buffer_delete(_buf);

    show_debug_message("I was killed (pid=" + string(other.my_pid) + ") — sent kill report");
}

instance_destroy();

if (oPlayerHitbox.dead_state = false && owner_id != oPlayerHitbox.id && oBullet.time_phase == oPlayerHitbox.time_phase){
	oPlayerHitbox.hitpoints -= 10;
	instance_destroy(self);
}
