//direction
image_angle = direction;

//despawn
if (x < 0 || x > room_width || y < 0 || y > room_height)
{
	emitAudio(x, y, sfxPop); //debug - remove later
    instance_destroy();
	
}
