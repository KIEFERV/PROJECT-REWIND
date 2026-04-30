/// oBullet — Collision with oPlayerHitbox

if (other.id == owner_id) exit;
if (other.dead_state) exit;

other.hitpoints -= damage;

// If this kill finished the player, send kill report to server
if (other.hitpoints <= 0) {
    var _buf = buffer_create(5, buffer_fixed, 1);
    buffer_write(_buf, buffer_u8,  11);           // PKT_KILL_REPORT
    buffer_write(_buf, buffer_u16, other.my_pid); // victim pid
    buffer_write(_buf, buffer_u16, other.my_pid); // placeholder — server uses sender's pid as killer
    network_send_udp_raw(global.socket, global.ip_address, global.port, _buf, buffer_tell(_buf));
    buffer_delete(_buf);
}

instance_destroy();
