/// oBullet — Collision with oPlayerHitbox

if (other.id == owner_id) exit;
if (other.dead_state) exit;

other.hitpoints -= damage;

if (other.hitpoints <= 0) {
    other.hitpoints  = 0;
    other.dead_state = true;
    other.visible    = false;
    global.player_alive = false;

    // Send kill report — shooter (owner) killed the victim
    // Packet: [u8:11][u16:killer_pid][u16:victim_pid]
    var _killer_pid = my_pid;        // shooter's pid (this oPlayerHitbox fired the bullet)
    var _victim_pid = other.my_pid;  // who got hit

    var _buf = buffer_create(5, buffer_fixed, 1);
    buffer_write(_buf, buffer_u8,  11);           // PKT_KILL_REPORT
    buffer_write(_buf, buffer_u16, _killer_pid);  // killer
    buffer_write(_buf, buffer_u16, _victim_pid);  // victim
    network_send_udp_raw(global.socket, global.ip_address, global.port, _buf, buffer_tell(_buf));
    buffer_delete(_buf);

    show_debug_message("Kill: pid=" + string(_killer_pid) + " killed pid=" + string(_victim_pid));
}

instance_destroy();
