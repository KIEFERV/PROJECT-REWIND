/// oBullet Step_0

image_angle = direction;


//Bullets not equal to your state cannot be seen.
if (time_phase != oPlayerHitbox.time_phase){
	image_alpha = 0;
} else {
	if (is_ghost) { // Ghost bullets (rewind past-phase) are semi-transparent (ty for whoever did this its cool --matt)
	    image_alpha = 0.35;
	} else {
	    image_alpha = 1;
	}
}

// Despawn when out of bounds
if (x < 0 || x > room_width || y < 0 || y > room_height) {
    instance_destroy();
}

