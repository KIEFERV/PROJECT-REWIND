// run parent step first
event_inherited();

// make sure player exists
if (!instance_exists(oPlayerHitbox)) exit;

var dir = point_direction(x, y, oPlayerHitbox.x, oPlayerHitbox.y);
image_angle = dir;

// cooldown
if (fire_timer > 0)
{
    fire_timer--;
}
else
{
    var spawn_offset = 10;

    var bx = x + lengthdir_x(spawn_offset, dir);
    var by = y + lengthdir_y(spawn_offset, dir);

    var b = instance_create_layer(bx, by, "Instances", oEnemyBullet);

    b.direction = dir;
    b.speed = bullet_speed;
    b.image_angle = dir;

    fire_timer = fire_rate;
}