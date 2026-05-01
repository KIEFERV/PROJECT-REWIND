function plr_rewind(){
// Move backwards through buffer

	repeat (REWIND_SPEED) {
	 playback_index--;
    rewind_frames_travelled++;

    if (playback_index < 0) {
        playback_index = buffer_size - 1;
    }
    
    // stop when we've reached the oldest frame, or exhausted unfilled buffer
    if (buffer_filled && playback_index == buffer_index) {
        plr_enter_past();
        break;
    } else if (!buffer_filled && playback_index <= 0) {
        plr_enter_past();
        break;
    }
}
		

		// Apply stored state
	    x = pos_x[playback_index];
	    y = pos_y[playback_index];
	    image_angle = pos_dir[playback_index];
}

function plr_enter_past(){
	rewind_active = false;
	show_debug_message("Time phase = " + time_phase);
	show_debug_message("rewind_frames_travelled = " + string(rewind_frames_travelled));
	time_phase = "past";
	time_cd = time_cd_max;
	show_debug_message("Time phase = " + time_phase);
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
		ghost_ref = instance_create_layer(ghostX, ghostY, "layer_barrier_wall", oGhost);
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

function rewindable_playback(){
	var frame = oRewindParent.rewindable_states[oRewindParent.playback_index];
    
    // loop through every state snapshot in this frame
    for (var i = 0; i < array_length(frame); i++) {
        var state = frame[i];
		
         switch (state.object_index) { //switch holding various restore logics, if needed, for object types.
        case oBullet:
            // bullet-specific restore logic
			
			
			// try to find an existing ghost matching this bullet_id
		    var ghost = noone;
		    with (oRewindable) {
		        if (is_ghost && bullet_id == state.bullet_id) {
		            ghost = id;
		            break;
		        }
		    }
    
		    if (instance_exists(ghost)) {
				
		        // already exists, just update its position
		        ghost.x = state.x;
		        ghost.y = state.y;
		        ghost.direction = state.direction;
		        ghost.speed = state.speed;
				
		    } else {
		        // doesn't exist yet, spawn it
		        var ghost = instance_create_layer(state.x, state.y, "layer_instances", oBullet);
				ghost.time_phase = oPlayerHitbox.time_phase
				ghost.owner_id = oPlayerHitbox.id;
		        ghost.is_ghost = true;
		        ghost.bullet_id = state.bullet_id;
				ghost.speed = 0;
		    }
        break;
	}	
}
}