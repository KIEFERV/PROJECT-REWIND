if( time_phase = "present"){
	if (!rewind_active) {
		
	//rewindable object recording
	rewindable_states[buffer_index] = [];
	with (oRewindable){
		if(!is_ghost){
			rewind_get_state(oRewindParent.buffer_index);
		}
	}	
	// Record current player
	    pos_x[buffer_index] = x;
	    pos_y[buffer_index] = y;
	    pos_dir[buffer_index] = image_angle;

	 // Advance index (wrap around)
	    buffer_index++;
	    if (buffer_index >= buffer_size) {
			show_debug_message("Buffer wrapping — buffer_filled was: " + string(buffer_filled));
	        buffer_index = 0;
	        buffer_filled = true;
			show_debug_message("Buffer wrapped — rewind_frames_travelled: " + string(rewind_frames_travelled));

	    }


	} else {
		plr_rewind();
		rewindable_playback();
	}

}

