//direction
image_angle = direction;

//despawn
if (x < 0 || x > room_width || y < 0 || y > room_height)
{
	emitAudio(x, y, sfxPop); //debug - remove later
    instance_destroy();
}
<<<<<<< HEAD

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
}}
=======
>>>>>>> parent of 1938120 (Dummies n More)
