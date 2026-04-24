/// @description Player Movement Test

// Debug Options
debug_menu = true; // Debug menu toggle (!!!CHANGE TO FALSE LATER)
show_GUI = true;

// Networking
net_send_timer = 0;

scr_powerup_init(self);

shoot_timer = 0;
cover_cooldown = 0;

// ---------- Power-up globals safety ----------
if (!variable_global_exists("POWER_FIRE_RATE")) global.POWER_FIRE_RATE = "fire_rate";
if (!variable_global_exists("POWER_MOVE_SPEED")) global.POWER_MOVE_SPEED = "move_speed";
if (!variable_global_exists("POWER_RICOCHET")) global.POWER_RICOCHET = "ricochet";
if (!variable_global_exists("POWER_COVER")) global.POWER_COVER = "cover";
if (!variable_global_exists("POWER_GRAVITY_SHOT")) global.POWER_GRAVITY_SHOT = "gravity_shot";

// ---------- Loadout globals safety ----------
if (!variable_global_exists("primary_weapon")) global.primary_weapon = "pistol";
if (!variable_global_exists("secondary_weapon")) global.secondary_weapon = "shotgun";

primary_weapon = global.primary_weapon;
secondary_weapon = global.secondary_weapon;

// -- Player Stats --

// Movement
base_move_speed_max = 8; // Base player movement speed
base_move_accel = 1.2;
base_move_decel = 0.8;
player_look_dir = 0;
sprinting = false;
sneaking = false;
can_sprint = true;
can_sneak = true;

// Health Variables
max_hp = hitpoints;

// Gun variables
mag_size = 30;
ammo_in_mag = mag_size;
ammo_reserve = 120;
reload_time = 45;
reload_timer = 0.5;
reloading = false;

// ---------- Power-up gameplay values ----------
scr_powerup_init(self);

// Match your existing movement system to power-up values
base_move_speed_max = base_move_speed_max;
move_speed = base_move_speed;

// Fire-rate system
base_fire_delay = 15;
fire_delay = base_fire_delay;
fireRate = fire_delay;
shoot_timer = 0;

// Power flags
can_ricochet = false;
can_place_cover = false;
can_gravity_shot = false;
max_cover_count = 0;
cover_cooldown = 0;

// Rewind set vars
time_phase = "present";

// Player States
dead_state = false;

// -----------------------------------------------------------------------

// NETWORKING (TEMP?)
time_remaining = 180;
is_host = false;

// Socket was created in lobby, just grab it
if (global.socket == -1) {
    show_debug_message("ERROR: No socket from lobby!");
    global.socket = network_create_socket(network_socket_udp);
}

socket = global.socket;
my_pid = global.my_pid;

#region Functions

// Spawn a bullet
function spawnBullet(_spawn_x, _spawn_y, _dir, _myID) {
    var bullet_inst = instance_create_layer(_spawn_x, _spawn_y, "layer_instances", oBullet);

    bullet_inst.owner_id = _myID;
    bullet_inst.owner = id;

    bullet_inst.direction = _dir;
    bullet_inst.speed = 12;
    bullet_inst.image_angle = bullet_inst.direction;

    bullet_inst.can_ricochet = can_ricochet;
    bullet_inst.ricochet_count = can_ricochet ? 2 : 0;

    bullet_inst.is_gravity_shot = can_gravity_shot;
    bullet_inst.gravity_radius = can_gravity_shot ? 140 : 0;
    bullet_inst.gravity_duration = can_gravity_shot ? room_speed * 2 : 0;
    bullet_inst.gravity_pull = can_gravity_shot ? 1.1 : 0;
}

#endregion

// Makes the Audio Listener on the player look properly
audio_listener_orientation(0, 1, 0, 0, 0, 1);

other_players = ds_map_create();

event_inherited();