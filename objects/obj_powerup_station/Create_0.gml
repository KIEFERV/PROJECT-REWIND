cooldown_time = room_speed * 8;
cooldown_timer = 0;

pickup_range = 28;

power_list = [
    global.POWER_FIRE_RATE,
    global.POWER_MOVE_SPEED,
    global.POWER_RICOCHET,
    global.POWER_COVER,
    global.POWER_GRAVITY_SHOT
];

current_power = power_list[irandom(array_length(power_list) - 1)];