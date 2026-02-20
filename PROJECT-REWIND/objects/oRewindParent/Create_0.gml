//Time Phases
time_phase = "present";

//REWIND Buffer

buffer_size = 300; //(5 seconds @ 60 fps), goes by frames(?)
buffer_index = 0;
rewind = false;
rewind_active = false;

//Create buffer arrays-- a different array storing position/other data for each data type stored.
pos_x = array_create(buffer_size, x);
pos_y = array_create(buffer_size, y);
pos_dir = array_create(buffer_size, image_angle); //optional if direction is important (direction, image_angle, etc)

//Buffer tracker (tracks if it's been filled once already)

buffer_filled = false;