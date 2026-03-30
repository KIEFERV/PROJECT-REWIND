function plr_enter_past(){
	rewind_active = false;
	show_debug_message("Time phase = " + time_phase);
	time_phase = "past";
	image_alpha = 1;
	oGhost.image_alpha = 0.5;
	
	//THIS is the part when objects start replaying, since the player will be done going back in time.
		anchor_index = buffer_index;
		anchor_x = x;
		anchor_y = y;

		// now rewind the read head back
		// Use actual frames travelled rather than full buffer
		buffer_read_index = (buffer_index + 1) mod buffer_size;
		past_duration = rewind_frames_travelled;
		past_frames_elapsed = 0;

}

function plr_travel_start(){
	
		rewind_active = true;
		visible = true;  // optional, hide original player
		image_alpha = 0.5; // semi-transparent

		// Spawn ghost in past
		ghostX = x;
		ghostY = y;
		ghost_ref = instance_create_layer(ghostX, ghostY, "Instances", oGhost);
}

function return_to_present(){

	if (time_phase = "past"){
	
	// Teleport back to where the ghost is
    x = ghostX;
    y = ghostY;
	//could play a little animation here :P
    
    // Destroy the ghost object
    if (instance_exists(ghost_ref)) {
        instance_destroy(ghost_ref);
    }
	
	time_phase = "present"
	
	}
	
}