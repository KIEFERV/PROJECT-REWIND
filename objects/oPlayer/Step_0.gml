// hitbox
x = oPlayerHitbox.x;
y = oPlayerHitbox.y;

//rotation
image_angle = point_direction(x, y, oCrosshair.x, oCrosshair.y);

//shooting
if (mouse_check_button_pressed(mb_left))
{
    if (!reloading && ammo_in_mag > 0)
    {
        var b = instance_create_layer(x, y, "Instances", oBullet);

        b.direction = point_direction(x, y, oCrosshair.x, oCrosshair.y);
        b.speed = 12;
        b.image_angle = b.direction;

        ammo_in_mag -= 1;
    }
}

//reload
if (keyboard_check_pressed(ord("R")))
{
    if (!reloading && ammo_in_mag < mag_size && ammo_reserve > 0)
    {
        reloading = true;
        reload_timer = reload_time;
    }
}

if (reloading)
{
    reload_timer -= 1;

    if (reload_timer <= 0)
    {
        var needed = mag_size - ammo_in_mag;
        var loaded = min(needed, ammo_reserve);

        ammo_in_mag += loaded;
        ammo_reserve -= loaded;

        reloading = false;
    }
}