if (async_load[? "type"] != network_type_data) exit;

var buf = async_load[? "buffer"];
buffer_seek(buf, buffer_seek_start, 0);

// DEBUG
//show_debug_message("Buffer size = " + string(buffer_get_size(buf)));

var ptype = buffer_read(buf, buffer_u8);  // read the type byte first
//show_debug_message("Packet received! type=" + string(ptype));

// Type 2 = server is telling us our own player ID
if (ptype == 2) {
    my_pid = buffer_read(buf, buffer_u16);
    show_debug_message("My player ID is: " + string(my_pid));
    exit;
}

// Type 1 = another player's state
if (ptype == 1) {
    var pid       = buffer_read(buf, buffer_u16);  // save their pid
    var ox        = buffer_read(buf, buffer_f32);  // save their x
    var oy        = buffer_read(buf, buffer_f32);  // save their y
    var ohp       = buffer_read(buf, buffer_u8);   // save their health
    var oanim     = buffer_read(buf, buffer_u8);   // save their anim frame
	var ofacing   = (buffer_read(buf, buffer_u8) / 255.0) * 360; // unpack back to 0-360
	//show_debug_message("ofacing = " + string(ofacing));

    // Store in map keyed by numeric ID
    var entry = ds_map_find_value(other_players, pid);
    if (is_undefined(entry)) {
        entry = array_create(5);
        ds_map_add(other_players, pid, entry);
        show_debug_message("New other player: " + string(pid));
    }
    entry[0] = ox;
    entry[1] = oy;
    entry[2] = ohp;
    entry[3] = oanim;
    entry[4] = ofacing;
	exit;
}

// Type 4 = another player fired a bullet
if (ptype == 4){

	var shooter_pid = buffer_read(buf, buffer_u16);
	var bx = buffer_read(buf, buffer_f32);
	var by = buffer_read(buf, buffer_f32);
	var bdir = (buffer_read(buf, buffer_u8) / 255.0) * 360;
	
	/*
	show_debug_message("shooter_pid=" + string(shooter_pid) +
					   " my_pid=" + string(my_pid) +
					   " bx=" + string(bx) + " by=" + string(by) +
					   " bdir=" + string(bdir));
	*/
	
	if (shooter_pid != my_pid){
		spawnBullet(bx, by, bdir);
		//USE ENEMY BULLT ON PEW PEW BRANCH TO DIFFERENTIATE KILLS???
	
		//show_debug_message("Bullet Spawned!");
		//show_debug_message("Bullet spawned at " + string(bx) + "," + string(by));
	}
	
	exit;
}

// Type 5 = timer updat efrom server
if (ptype == 5){
	time_remaining = buffer_read(buf, buffer_u16);
    exit;
}

// Type 6 = match over
if (ptype == 6){
	//room_goto();
	show_debug_message("Match Ended!");
	exit;
}