if (cooldown_timer > 0) {
    cooldown_timer--;
    exit;
}

var p = instance_nearest(x, y, oPlayerHitbox);

if (p != noone) {
    var dist = point_distance(x, y, p.x, p.y);

    if (dist <= pickup_range) {
        var chosen_power = current_power;

        var duration_steps = room_speed * 8;
        var magnitude = 1;

        switch (chosen_power) {
            case global.POWER_FIRE_RATE:
                duration_steps = room_speed * 6;
                magnitude = 8;
            break;

            case global.POWER_MOVE_SPEED:
                duration_steps = room_speed * 6;
                magnitude = 2;
            break;

            case global.POWER_RICOCHET:
                duration_steps = room_speed * 8;
                magnitude = 1;
            break;

            case global.POWER_COVER:
                duration_steps = room_speed * 10;
                magnitude = 3;
            break;

            case global.POWER_GRAVITY_SHOT:
                duration_steps = room_speed * 8;
                magnitude = 1;
            break;
        }

        if (!variable_instance_exists(p, "powerups")) {
            scr_powerup_init(p);
        }

        scr_powerup_add(p, chosen_power, duration_steps, magnitude);

        current_power = power_list[irandom(array_length(power_list) - 1)];
        cooldown_timer = cooldown_time;
    }
}