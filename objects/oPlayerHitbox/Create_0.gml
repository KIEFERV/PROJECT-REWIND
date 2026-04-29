/// @description Player Movement Test

debug_menu = true; // Debug menu toggle (!!!CHANGE TO FALSE LATER)
show_GUI   = true; // Show HUD/GUI elements

base_move_speed_max = 8;
base_move_accel = 2;
base_move_decel = 0.8;

sprinting = false;
sneaking  = false;
can_sprint = true;
can_sneak  = true;

// Rewind set vars
time_phase = "present";

// Gun variables
mag_size    = 30;
ammo_in_mag = mag_size;
ammo_reserve = 120;
reload_time  = 45;
reload_timer = 0.5;
reloading    = false;

max_hp = 100;
facing = 0;

// Networking
time_remaining = 180;
is_host        = false;
net_send_timer = 0;

// Safe globals
if (!variable_global_exists("socket"))     global.socket     = -1;
if (!variable_global_exists("ip_address")) global.ip_address = "";
if (!variable_global_exists("port"))       global.port       = 0;
if (!variable_global_exists("my_pid"))     global.my_pid     = 0;

// Grab socket from lobby
if (global.socket == -1) {
    show_debug_message("ERROR: No socket from lobby!");
    global.socket = network_create_socket(network_socket_udp);
}
socket = global.socket;
my_pid = global.my_pid;

// ── Spawn at position matching our pid ───────────────────────────────────
// global.my_pid is set in oLobby when the server assigns a pid.
// oSpawnPoint instances in the room are used as spawn positions.
if (my_pid > 0) {
    var _spawn_count = instance_number(oSpawnPoint);
    if (_spawn_count > 0) {
        var _spawn_idx = (my_pid - 1) mod _spawn_count;
        var _i = 0;
        with (oSpawnPoint) {
            if (_i == _spawn_idx) {
                other.x = x;
                other.y = y;
                show_debug_message("Spawned at point " + string(_spawn_idx + 1)
                    + " (" + string(x) + "," + string(y) + ")");
                break;
            }
            _i++;
        }
    } else {
        // No spawn points — spread players in a circle around room centre
        var _angle  = ((my_pid - 1) / 4.0) * 360;
        var _radius = 400;
        x = room_width  / 2 + lengthdir_x(_radius, _angle);
        y = room_height / 2 + lengthdir_y(_radius, _angle);
        show_debug_message("No spawn points — fallback for pid " + string(my_pid));
    }
} else {
    show_debug_message("WARNING: my_pid is 0 at spawn time — no repositioning");
}

#region Functions

function spawnBullet(_x, _y, _dir) {
    var b = instance_create_layer(_x, _y, "layer_instances", oBullet);
    b.direction   = _dir;
    b.speed       = 12;
    b.image_angle = b.direction;
}

#endregion

// Audio listener
audio_listener_orientation(0, 1, 0, 0, 0, 1);

other_players = ds_map_create();

event_inherited();
