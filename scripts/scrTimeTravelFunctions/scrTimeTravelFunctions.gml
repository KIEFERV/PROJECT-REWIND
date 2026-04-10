function plr_enter_past(){
	rewind_active = false;
	show_debug_message("Time phase = " + time_phase);
	show_debug_message("rewind_frames_travelled = " + string(rewind_frames_travelled));
	time_phase = "past";
	image_alpha = 1;
	oGhost.image_alpha = 0.5;
	
	
	//THIS is the part when objects start replaying, since the player will be done going back in time.
		anchor_index = playback_index;
		anchor_x = x;
		anchor_y = y;

		// now rewind the read head back
		// Use actual frames travelled rather than full buffer
		buffer_read_index = (playback_index + 1) mod buffer_size;
		past_duration = rewind_frames_travelled;
		rewind_frames_travelled = 0;
		past_frames_elapsed = 0;

}

function plr_travel_start(){
		playback_index = (buffer_index - 1 + buffer_size) mod buffer_size;
		rewind_active = true;
		visible = true;  // optional, hide original player
		image_alpha = 0.5; // semi-transparent

		// Spawn ghost in past
		ghostX = x;
		ghostY = y;
		ghost_ref = instance_create_layer(ghostX, ghostY, "layer_instances", oGhost);
}

function return_to_present(){

	if (time_phase = "past"){
		show_debug_message("return_to_present called, buffer_filled = " + string(buffer_filled));

	
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