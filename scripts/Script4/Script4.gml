function respawn_player()
{
    var p = instance_find(oPlayerHitbox,0);
    if (p != noone)
    {
        p.hp = p.max_hp;
        p.is_dead = false;
        p.x = room_width/2;
        p.y = room_height/2;

        // Reset weapons
        for (var i = 0; i < array_length(p.weapons); i++)
        {
            p.weapons[i].ammo_in_mag = p.weapons[i].mag_size;
        }
        p.current_weapon_index = 0;
        p.current_weapon = p.weapons[0];
    }
}