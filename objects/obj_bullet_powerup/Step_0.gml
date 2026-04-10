if (x < 0 || x > room_width || y < 0 || y > room_height) {
    if (can_ricochet && ricochet_count > 0) {
        if (x <= 0 || x >= room_width) {
            direction = 180 - direction;
            ricochet_count--;
            x = clamp(x, 1, room_width - 1);
        }

        if (y <= 0 || y >= room_height) {
            direction = -direction;
            ricochet_count--;
            y = clamp(y, 1, room_height - 1);
        }
    } else {
        instance_destroy();
    }
}