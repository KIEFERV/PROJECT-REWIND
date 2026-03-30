// Move bullet
x += lengthdir_x(speed, direction);
y += lengthdir_y(speed, direction);

image_angle = direction;

// Destroy if outside room
if (x < 0 || x > room_width || y < 0 || y > room_height)
{
    instance_destroy();
    exit;
}

// Wall collision
if (place_meeting(x, y, oCollisionBox))
{
    instance_destroy();
    exit;
}

// Enemy collision
var target = instance_place(x, y, oEnemyParent);

if (target != noone)
{
    // Apply damage
    var dmg_amount = 1;
    target.hp -= dmg_amount;

    // Create floating damage text
    if (instance_exists(oDamageText))
    {
        var dmg = instance_create_depth(target.x, target.y - 10, -100, oDamageText);
        dmg.text_value = dmg_amount;
    }

    // Destroy enemy if dead
    if (target.hp <= 0)
        instance_destroy(target);

    // Destroy bullet
    instance_destroy();
}