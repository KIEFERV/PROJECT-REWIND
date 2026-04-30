/// oBullet — Collision with oPlayerHitbox

if (other.id == owner_id) exit;
if (other.dead_state) exit;

other.hitpoints -= damage;

if (other.hitpoints <= 0) {
    other.hitpoints     = 0;
    other.dead_state    = true;
    other.visible       = false;
    other.global_player_alive = false;  // can't access global directly from other, use a flag

    // Get killer pid from the owner instance
    var _killer_pid = 0;
    if (instance_exists(owner_id)) {
        _killer_pid = owner_id.my_pid;
    }
    var _victim_pid = other.my_pid;

    // Send kill report
    var _buf = buffer_create(5, buffer_fixed, 1);
    buffer_write(_buf, buffer_u8,  11);
    buffer_write(_buf, buffer_u16, _killer_pid);
    buffer_write(_buf, buffer_u16, _victim_pid);
    network_send_udp_raw(global.socket, global.ip_address, global.port, _buf, buffer_tell(_buf));
    buffer_delete(_buf);

    // Mark local player as dead if victim is us
    if (_victim_pid == global.my_pid) {
        global.player_alive = false;
    }

    show_debug_message("Kill: pid=" + string(_killer_pid) + " killed pid=" + string(_victim_pid));
}

instance_destroy();
