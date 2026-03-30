if (is_dead)
{
    player_hor_speed = 0;
    player_vert_speed = 0;
    exit;
}

if (hp <= 0 && !is_dead)
{
    is_dead = true;
    show_death_screen = true;
}

if (is_dead && keyboard_check_pressed(vk_space))
{
    hp = max_hp;
    x = spawn_x;
    y = spawn_y;
    is_dead = false;
    show_death_screen = false;

    // Reset weapons
    for (var i = 0; i < array_length(weapons); i++)
    {
        weapons[i].ammo_in_mag = weapons[i].mag_size;
        weapons[i].ammo_reserve = weapons[i].max_reserve;
        weapons[i].reloading = false;
        weapons[i].fire_timer = 0;
    }
    current_weapon_index = 0;
    current_weapon = weapons[0];

    // Reset enemies
    with (oEnemyParent)
    {
        hp = max_hp;
    }
}

///@description Player Logic
/*
//get inputs
key_right  = keyboard_check(ord("D"));
key_left   = keyboard_check(ord("A"));
key_up     = keyboard_check(ord("W"));
key_down   = keyboard_check(ord("S"));
key_sprint = keyboard_check(vk_shift);
key_sneak = keyboard_check(vk_alt);

if (keyboard_check_released(ord("M"))) debug_menu = !debug_menu;

//Base movement
var base_hor  = sign(key_right - key_left) * move_speed;
var base_vert = sign(key_down - key_up) * move_speed;

// Look Direction
facing = point_direction(x, y, mouse_x, mouse_y);

// Sprint
var sprint_speed = key_sprint ? 1.5 : 1.0;
sprinting = key_sprint;

// Player speed with sprint multiplier
player_hor_speed  = base_hor * sprint_speed;
player_vert_speed = base_vert * sprint_speed;
	//player states
//Sprinting
var sprint_speed;
if (key_sprint && !key_sneak){
	sprinting = true;
	can_sneak = false
	modifier_sprint = 1.5;
}else{
	// Player is not Sprinting
	sprinting = false;
	can_sneak = true;
	modifier_sprint = 1.0;
}

// Walking
var modifier_sneak;
if (key_sneak && can_sneak && !key_sprint){
	// Player is Sneaking
	sneaking = true;
	can_sprint = false;
	modifier_sneak = 0.5;
}else{
	// Player is not Sneaking
	sneaking = false;
	can_sprint = true;
	modifier_sneak = 1.0;
}

	//Apply the movement multipliers
player_hor_speed = base_hor * (sprint_speed) * (sneak_speed);
player_vert_speed = base_vert * (sprint_speed) * (sneak_speed);

// Collision check
if (place_meeting(x + player_hor_speed, y, oCollisionBox)) player_hor_speed = 0;
if (place_meeting(x, y + player_vert_speed, oCollisionBox)) player_vert_speed = 0;

//Move player

// Touching Slowing Floor
var modifier_floor_slow_max,
	modifier_floor_slow_accel;
if (place_meeting(x, y, oFloorSlow)){
	// Player is Slowed
	// add slow check boolean here?
	modifier_floor_slow_max = 0.5;
	modifier_floor_slow_accel = 0.8;
}else{
	//Player is not Slowed
	modifier_floor_slow_max = 1.0;
	modifier_floor_slow_accel = 1.0;
}

// Touching Boost Floor
var modifier_floor_boost_max,
	modifier_floor_boost_accel;
if (place_meeting(x, y, oFloorBoost)){
	// Player is Boosting
	// add boosting check boolean here?
	modifier_floor_boost_max = 1.2;
	modifier_floor_boost_accel = 1.1;
}else{
	// Player is not Boosting
	modifier_floor_boost_max = 1.0;
	modifier_floor_boost_accel = 1.0;
}
#endregion


//Audio listener
audio_listener_position(x, y, 0);

//dead
if (is_dead) exit;

//Weapon logic
var w = current_weapon;

// Fire cooldown
if (w.fire_timer > 0) w.fire_timer--;

// Reload
if (keyboard_check_pressed(ord("R")) && !w.reloading && w.ammo_in_mag < w.mag_size && w.ammo_reserve > 0)
{
    w.reloading = true;
    w.reload_timer = w.reload_time;
}

if (w.reloading)
{
    w.reload_timer--;
    if (w.reload_timer <= 0)
    {
        var needed = w.mag_size - w.ammo_in_mag;
        var load = min(needed, w.ammo_reserve);
        w.ammo_in_mag += load;
        w.ammo_reserve -= load;
        w.reloading = false;
    }
}

// weapon switching
if (keyboard_check_pressed(ord("1"))) current_weapon_index = 0;
if (keyboard_check_pressed(ord("2"))) current_weapon_index = 1;
if (keyboard_check_pressed(ord("3"))) current_weapon_index = 2;

current_weapon = weapons[current_weapon_index];

// shooting
var shoot_pressed = mouse_check_button_pressed(mb_left);
var shoot_held    = mouse_check_button(mb_left);
var trigger       = w.automatic ? shoot_held : shoot_pressed;

if (trigger && !w.reloading && w.fire_timer <= 0 && w.ammo_in_mag > 0)
{
    var base_dir = point_direction(x, y, mouse_x, mouse_y);

var spawn_offset = 8;
var bx = x + lengthdir_x(spawn_offset, base_dir);
var by = y + lengthdir_y(spawn_offset, base_dir);

// spread center
var half_spread = w.spread / 2;

for (var i = 0; i < w.pellets; i++)
{
    var pellet_dir;

    // evenly spaced spread instead of random
    if (w.pellets > 1)
    {
        pellet_dir = base_dir - half_spread + (i * (w.spread / (w.pellets - 1)));
    }
    else
    {
        pellet_dir = base_dir;
    }

    var b = instance_create_layer(bx, by, "Instances", oBullet);
    
    b.direction = pellet_dir;
    b.speed = w.bullet_speed;
    b.image_angle = pellet_dir;
    b.owner = id;
}

    w.ammo_in_mag -= 1;
    w.fire_timer = w.fire_rate;

    //debug message
    show_debug_message("Fired weapon: " + w.name + " Ammo: " + string(w.ammo_in_mag));
    }
*/

#endregion

#region Shooting

// hitbox
//x = oPlayerHitbox.x; //no longer needed
//y = oPlayerHitbox.y; // no longer needed

//rotation
image_angle = point_direction(x, y, mouse_x, mouse_y);

//shooting
if (mouse_check_button_pressed(mb_left))
{
    if (!reloading && ammo_in_mag > 0)
    {
        var b = instance_create_layer(x, y, "layer_instances", oBullet);

        b.direction = point_direction(x, y, mouse_x, mouse_y);
        b.speed = 12;
        b.image_angle = b.direction;

        ammo_in_mag -= 1;
    }
}


//reload
if (keyboard_check_pressed(ord("R")))
{
    if (!reloading && ammo_in_mag < mag_size && ammo_reserve > 0)
    {
        reloading = true;
        reload_timer = reload_time;
    }
}

if (reloading)
{
    reload_timer -= 1;

    if (reload_timer <= 0)
    {
        var needed = mag_size - ammo_in_mag;
        var loaded = min(needed, ammo_reserve);

        ammo_in_mag += loaded;
        ammo_reserve -= loaded;

        reloading = false;
    }
}

#endregion

// Applies the movement logic (Character_lib) to the player
add_movement_input(_input_x, _input_y);


#region Networking

var buf = buffer_create(32, buffer_fixed, 1);
buffer_seek(buf, buffer_seek_start, 0);

buffer_write(buf, buffer_u8,  1);           // type = 1 (player state)
buffer_write(buf, buffer_f32, x);           // x position
buffer_write(buf, buffer_f32, y);           // y position
buffer_write(buf, buffer_u8,  hitpoints);   // health (0-255)
buffer_write(buf, buffer_u8,  image_index); // animation frame (unused for now)
buffer_write(buf, buffer_u8,  round((facing / 360.0) * 255)); // facing angle

network_send_udp_raw(socket, "127.0.0.1", 7777, buf, buffer_tell(buf));
buffer_delete(buf);

#endregion

//inherit the code from parent (oCharacterController)
event_inherited();