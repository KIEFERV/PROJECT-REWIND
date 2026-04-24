/// @description Player Movement Test

debug_menu = true; // Debug menu toggle (!!!CHANGE TO FALSE LATER)

net_send_timer = 0;

base_move_speed_max = 8; //Base player movement speed
base_move_accel = 2;
base_move_decel = 0.8;

sprinting = false; // Whether or not the player is sprinting
sneaking = false; // Whether or not the player is sneaking/walking
can_sprint = true; // Is the player allowed to sprint
can_sneak = true; // Is the player allowed to walk

//Rewind set vars
time_phase = "present";

//Gun variables — now driven by weapon system
// ── Weapon definitions 

weapon_defs = ds_map_create();

var _ar  = ds_map_create();
ds_map_add(_ar,  "mag_size",    30);  ds_map_add(_ar,  "max_reserve", 120);
ds_map_add(_ar,  "fire_delay",  8);   ds_map_add(_ar,  "bullet_speed", 14);
ds_map_add(_ar,  "damage",      1);   ds_map_add(_ar,  "reload_time",  90);
ds_map_add(_ar,  "type", "auto");
ds_map_add(weapon_defs, "assault_rifle", _ar);

var _sg  = ds_map_create();
ds_map_add(_sg,  "mag_size",    5);   ds_map_add(_sg,  "max_reserve", 20);
ds_map_add(_sg,  "fire_delay",  25);  ds_map_add(_sg,  "bullet_speed", 12);
ds_map_add(_sg,  "damage",      0.5); ds_map_add(_sg,  "reload_time",  120); 
ds_map_add(_sg,  "type", "shotgun");
ds_map_add(weapon_defs, "shotgun", _sg);

var _smg = ds_map_create();
ds_map_add(_smg, "mag_size",    24);  ds_map_add(_smg, "max_reserve", 96);
ds_map_add(_smg, "fire_delay",  5);   ds_map_add(_smg, "bullet_speed", 13);
ds_map_add(_smg, "damage",      1);   ds_map_add(_smg, "reload_time",  70);
ds_map_add(_smg, "type", "burst");
ds_map_add(weapon_defs, "smg", _smg);

var _sn  = ds_map_create();
ds_map_add(_sn,  "mag_size",    3);   ds_map_add(_sn,  "max_reserve", 15);
ds_map_add(_sn,  "fire_delay",  60);  ds_map_add(_sn,  "bullet_speed", 24);
ds_map_add(_sn,  "damage",      999); ds_map_add(_sn,  "reload_time",  150);
ds_map_add(weapon_defs, "sniper", _sn);

var _ps  = ds_map_create();
ds_map_add(_ps,  "mag_size",    12);  ds_map_add(_ps,  "max_reserve", 60);
ds_map_add(_ps,  "fire_delay",  15);  ds_map_add(_ps,  "bullet_speed", 12);
ds_map_add(_ps,  "damage",      1);   ds_map_add(_ps,  "reload_time",  60);
ds_map_add(_ps,  "type", "auto");
ds_map_add(weapon_defs, "pistol", _ps);

var _kn  = ds_map_create();
ds_map_add(_kn,  "mag_size",    1);   ds_map_add(_kn,  "max_reserve", 0);
ds_map_add(_kn,  "fire_delay",  20);  ds_map_add(_kn,  "bullet_speed", 0);
ds_map_add(_kn,  "damage",      1);   ds_map_add(_kn,  "reload_time",  0); 
ds_map_add(_kn,  "type", "melee");
ds_map_add(weapon_defs, "knife", _kn);

// ── Slot names 
if (!variable_global_exists("primary_weapon"))   global.primary_weapon   = "assault_rifle";
if (!variable_global_exists("secondary_weapon")) global.secondary_weapon = "pistol";

primary_name   = global.primary_weapon;
secondary_name = global.secondary_weapon;
active_slot    = 1; // 1 = primary, 2 = secondary

// ── Per-slot ammo
var _pdef = weapon_defs[? primary_name];
primary_ammo_mag     = _pdef[? "mag_size"];
primary_ammo_reserve = _pdef[? "max_reserve"];
primary_reloading    = false;
primary_reload_timer = 0;

var _sdef = weapon_defs[? secondary_name];
secondary_ammo_mag     = (secondary_name == "knife") ? 0 : _sdef[? "mag_size"];
secondary_ammo_reserve = (secondary_name == "knife") ? 0 : _sdef[? "max_reserve"];
secondary_reloading    = false;
secondary_reload_timer = 0;

// ── Burst-fire state 
burst_shots_left = 0;
burst_fire_timer = 0;
knife_swing_timer = 0;

var _adef       = weapon_defs[? primary_name];
mag_size        = _adef[? "mag_size"];
ammo_in_mag     = primary_ammo_mag;
ammo_reserve    = primary_ammo_reserve;
reloading       = false;
reload_timer    = 0;
reload_time     = _adef[? "reload_time"];
weapon_type     = _adef[? "type"];
fire_delay      = _adef[? "fire_delay"];
shoot_timer     = 0;
bullet_speed    = _adef[? "bullet_speed"];
bullet_damage   = _adef[? "damage"];

max_hp = 100;

facing = 0; 

//NETWORKING (TEMP?)
time_remaining = 180;
is_host = false;
// Socket was created in lobby, just grab it
if (global.socket == -1) {
    show_debug_message("ERROR: No socket from lobby!");
    // Fallback — create our own socket
    global.socket = network_create_socket(network_socket_udp);
}
socket = global.socket;
my_pid = global.my_pid;


#region Functions

// Spawn a bullet
function spawnBullet(_x, _y, _dir){
	var b = instance_create_layer(_x, _y, "layer_instances", oBullet);

        b.direction = _dir;
        b.speed = 12;
        b.image_angle = b.direction;
}

#endregion


// Makes the Audio Listener on the player look Properly
audio_listener_orientation(0, 1, 0, 0, 0, 1);

other_players = ds_map_create();


event_inherited();