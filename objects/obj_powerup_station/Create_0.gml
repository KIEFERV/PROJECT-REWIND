// Power list
power_list = [
    global.POWER_FIRE_RATE,
    global.POWER_MOVE_SPEED,
    global.POWER_RICOCHET,
    global.POWER_COVER,
    global.POWER_GRAVITY_SHOT
];

// Pick initial power
current_power = power_list[irandom(array_length(power_list) - 1)];

if (!variable_global_exists("POWER_FIRE_RATE")) global.POWER_FIRE_RATE = "fire_rate";
if (!variable_global_exists("POWER_MOVE_SPEED")) global.POWER_MOVE_SPEED = "move_speed";
if (!variable_global_exists("POWER_RICOCHET")) global.POWER_RICOCHET = "ricochet";
if (!variable_global_exists("POWER_COVER")) global.POWER_COVER = "cover";
if (!variable_global_exists("POWER_GRAVITY_SHOT")) global.POWER_GRAVITY_SHOT = "gravity_shot";

cooldown_time = room_speed * 8;
cooldown_timer = 0;

station_radius = 22;
pickup_range = 28;

