/// @description Player Movement Test
//Debug Options
debug_menu = true; // Debug menu toggle (!!!CHANGE TO FALSE LATER)
show_GUI = true;

//Networking
net_send_timer = 0;

//--Player Stats
//Movement
base_move_speed_max = 8; //Base player movement speed
base_move_accel = 2;
base_move_decel = 0.8;
facing = 0; // player look direction
sprinting = false; // Whether or not the player is sprinting
sneaking = false; // Whether or not the player is sneaking/walking
can_sprint = true; // Is the player allowed to sprint
can_sneak = true; // Is the player allowed to walk
//Health Variables
max_hp = hitpoints;
//Gun variables
mag_size = 30;
ammo_in_mag = mag_size;
ammo_reserve = 120;
reload_time = 45;
reload_timer = 0.5;
reloading = false;

//Rewind set vars
time_phase = "present";

//Player States
dead_state = false;





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
function spawnBullet(_x, _y, _dir, myID){
	var b = instance_create_layer(_x, _y, "layer_instances", oBullet);
		b.owner_id = myID;
        b.direction = _dir;
        b.speed = 12;
        b.image_angle = b.direction;
}

#endregion


// Makes the Audio Listener on the player look Properly
audio_listener_orientation(0, 1, 0, 0, 0, 1);

other_players = ds_map_create();


event_inherited();