/// @description Player Movement Test

debug_menu = true; // Debug menu toggle (!!!CHANGE TO FALSE LATER)

base_move_speed_max = 8; //Base player movement speed
base_move_accel = 2;
base_move_decel = 0.8;

sprinting = false; // Whether or not the player is sprinting
sneaking = false; // Whether or not the player is sneaking/walking
can_sprint = true; // Is the player allowed to sprint
can_sneak = true; // Is the player allowed to walk

// Makes the Audio Listener on the player look Properly
audio_listener_orientation(0, 1, 0, 0, 0, 1);

event_inherited();