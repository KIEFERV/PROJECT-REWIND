event_inherited();
function on_break(){
	
	//break anim
		show_debug_message("on_break() triggered! hp = " + string(wall_hp) + ", broken = " + string(broken));
		instance_create_layer(x, y, "Effects", oWoodBreakAnim);	
	//audio_play_sound(sWoodBreak, 1, false); (will add back when we have the sound)
	
	// Optional: fire bonus
    if (HitByLast == DAMAGE_TYPE.FIRE)  // you can track this in damage pipeline, may change this to directly check damage type, since the parent function takes that as an argument.
    {
        var splinters = 4;
        for (var i = 0; i < splinters; i++)
        {
            var shard = instance_create_layer(x, y, "Effects", oWoodSplinter);
            shard.direction = random(360);
            shard.speed = 2 + random(2);
            shard.damage = 1; //may change depending on how we handle player damage values.
        }
    }
}