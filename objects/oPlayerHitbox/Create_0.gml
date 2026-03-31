/// @description Player Movement Test

debug_menu = true; // Debug menu toggle (!!!CHANGE TO FALSE LATER)

base_move_speed_max = 8; //Base player movement speed
base_move_accel = 2;
base_move_decel = 0.8;

sprinting = false; // Whether or not the player is sprinting
sneaking = false; // Whether or not the player is sneaking/walking
can_sprint = true; // Is the player allowed to sprint
can_sneak = true; // Is the player allowed to walk

//Gun variables
mag_size = 30;
ammo_in_mag = mag_size;
ammo_reserve = 120;
reload_time = 45;
reload_timer = 0.5;
reloading = false;

max_hp = 100;

facing = 0; // player look direction

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

socket = network_create_socket(network_socket_udp);
network_connect_raw(socket, "127.0.0.1", 7777);
other_players = ds_map_create();

event_inherited();