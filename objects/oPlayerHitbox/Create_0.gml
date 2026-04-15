/// @description Player Movement Test

debug_menu = true; // Debug menu toggle (!!!CHANGE TO FALSE LATER)

base_move_speed_max = 8;
base_move_accel = 2;
base_move_decel = 0.8;

sprinting = false;
sneaking = false;
can_sprint = true;
can_sneak = true;

time_phase = "present";

mag_size = 30;
ammo_in_mag = mag_size;
ammo_reserve = 120;
reload_time = 45;
reload_timer = 0.5;
reloading = false;

max_hp = 100;

facing = 0;

#region Functions

function spawnBullet(_x, _y, _dir){
    var b = instance_create_layer(_x, _y, "layer_instances", oBullet);
    b.direction = _dir;
    b.speed = 12;
    b.image_angle = b.direction;
}

#endregion

audio_listener_orientation(0, 1, 0, 0, 0, 1);

// ── Networking ────────────────────────────────────────────────────────────────
// We use ONE UDP socket for everything:
//   • talking to the rendezvous server
//   • talking directly to each peer (after hole-punching)

RENDEZVOUS_IP   = "127.0.0.1"; // ← change to your server's public IP
RENDEZVOUS_PORT = 7777;

socket = network_create_socket(network_socket_udp);
// Bind to any local port (GML chooses one automatically when we first send)
network_connect_raw(socket, RENDEZVOUS_IP, RENDEZVOUS_PORT);

my_pid   = -1;  // assigned by server

// ds_map  pid (real)  →  array [ip_string, port, hole_punched]
// We key by numeric PID so lookups during draw / step are O(log n)
other_players = ds_map_create(); // pid → [x, y, hp, anim, facing]
peer_addrs    = ds_map_create(); // pid → [ip_string, port]

// Keepalive alarm: every 2 seconds send a type-0 ping to the server
// so the server doesn't time us out (server timeout = 5 s)
alarm[0] = room_speed * 2;

// Register with server immediately (type 0 = register / keepalive)
var _reg = buffer_create(1, buffer_fixed, 1);
buffer_write(_reg, buffer_u8, 0);
network_send_udp_raw(socket, RENDEZVOUS_IP, RENDEZVOUS_PORT, _reg, 1);
buffer_delete(_reg);

event_inherited();
