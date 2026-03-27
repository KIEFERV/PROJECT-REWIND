is_dead = false;          // track death
show_death_screen = false; // whether to draw death UI
spawn_x = x;              // original spawn point
spawn_y = y;

// Reset weapons (example)
current_weapon_index = 0;
weapons = [];

/// @description Player Movement Test

debug_menu = true; // Debug menu toggle (!!!CHANGE TO FALSE LATER)

base_move_speed_max = 8; //Base player movement speed
base_move_accel = 2;
base_move_decel = 0.8;

sprinting = false; // Whether or not the player is sprinting
sneaking = false; // Whether or not the player is sneaking/walking
can_sprint = true; // Is the player allowed to sprint
can_sneak = true; // Is the player allowed to walk
audio_listener_orientation(0, 1, 0, 0, 0, 1);
//dist = 0;

// Health
max_hp = 5;
hp = max_hp;
is_dead = false;

// Weapon structs
pistol = {
    name: "Pistol",
    mag_size: 12,
    ammo_in_mag: 12,
    ammo_reserve: 60,
    fire_rate: 15,
    fire_timer: 0,
    reload_time: 40,
    reload_timer: 0,
    bullet_speed: 12,
    automatic: false,
    spread: 0,
    pellets: 1,
    reloading: false
};

ar = {
    name: "AR",
    mag_size: 30,
    ammo_in_mag: 30,
    ammo_reserve: 120,
    fire_rate: 4,
    fire_timer: 0,
    reload_time: 60,
    reload_timer: 0,
    bullet_speed: 14,
    automatic: true,
    spread: 2,
    pellets: 1,
    reloading: false
};

shotgun = {
    name: "Shotgun",
    mag_size: 5,
    ammo_in_mag: 5,
    ammo_reserve: 25,
    fire_rate: 25,
    fire_timer: 0,
    reload_time: 70,
    reload_timer: 0,
    bullet_speed: 10,
    automatic: false,
    spread: 15,
    pellets: 5,
    reloading: false
};

// Weapon management
weapons = [pistol, ar, shotgun];
current_weapon_index = 0;
current_weapon = weapons[current_weapon_index];
player_health = 100;

// Makes the Audio Listener on the player look Properly
audio_listener_orientation(0, 1, 0, 0, 0, 1);

socket = network_create_socket(network_socket_udp);
network_connect_raw(socket, "127.0.0.1", 7777);
other_players = ds_map_create();

event_inherited();