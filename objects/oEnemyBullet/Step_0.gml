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

// Player collision
if (instance_exists(oPlayerHitbox))
{
    var player = instance_place(x, y, oPlayerHitbox);
    
    if (player != noone)
    {
        var dmg_amount = 1; // damage per bullet
        player.hp -= dmg_amount;

        // Create floating damage text
        if (instance_exists(oDamageText))
        {
            var dmg = instance_create_depth(target.x, target.y - 10, -100, oDamageText);
            dmg.text_value = dmg_amount;
        }

        instance_destroy();
    }
}