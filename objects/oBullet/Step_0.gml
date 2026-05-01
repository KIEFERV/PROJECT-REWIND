/// oBullet Step_0

image_angle = direction;

// Ghost bullets (rewind past-phase) are semi-transparent
if (is_ghost) {
    image_alpha = 0.35;
} else {
    image_alpha = 1;
}

// Despawn when out of bounds
if (x < 0 || x > room_width || y < 0 || y > room_height) {
    instance_destroy();
}

