if( time_phase = "present"){
	if (!rewind_active) { //want to add an additional condition here to check if its a player or not, since i dont want an object to be able to rewind in the exact way a player does.
	// Record current state
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

}

