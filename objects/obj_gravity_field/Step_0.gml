life--;
if (life <= 0) {
    instance_destroy();
    exit;
}

with (obj_player) {
    if (id != other.owner) {
        var dist = point_distance(x, y, other.x, other.y);

        if (dist <= other.radius && dist > 4) {
            var dir = point_direction(x, y, other.x, other.y);

            x += lengthdir_x(other.pull_strength, dir);
            y += lengthdir_y(other.pull_strength, dir);
        }
    }
}