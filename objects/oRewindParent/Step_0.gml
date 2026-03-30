<<<<<<< HEAD
	
if( time_phase = "present"){
	if (!rewind_active) { //want to add an additional condition here to check if its a player or not, since i dont want an object to be able to rewind in the exact way a player does.
=======
	if (!rewind) {
>>>>>>> parent of 9fe9b4f (had to break up the commit because )
	// Record current state
	    pos_x[buffer_index] = x;
	    pos_y[buffer_index] = y;
	    pos_dir[buffer_index] = image_angle;

	 // Advance index (wrap around)
	    buffer_index++;
	    if (buffer_index >= buffer_size) {
	        buffer_index = 0;
	        buffer_filled = true;
	    }


	} else {
	
	// Move backwards through buffer
	  var rewind_speed = 5; // tweak this

	repeat (rewind_speed) {
	    buffer_index--;
	
		if (buffer_index < 0) {
	        if (buffer_filled) {
	            buffer_index = buffer_size - 1;
	        } else {
	            buffer_index = 0;
				break;
	        }
			
	    }
		
		if (!buffer_filled && buffer_index == 0) rewind_active = false;
		if (buffer_filled == buffer_index) rewind_active = false;
	}

		// Apply stored state
	    x = pos_x[buffer_index];
	    y = pos_y[buffer_index];
	    image_angle = pos_dir[buffer_index];
	}

<<<<<<< HEAD
}
=======

>>>>>>> parent of 9fe9b4f (had to break up the commit because )

