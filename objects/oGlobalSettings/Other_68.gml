/*
if (async_load[? "type"] == network_type_data) {
    var buf = async_load[? "buffer"];
    buffer_seek(buf, buffer_seek_start, 0);
    var msg = buffer_read(buf, buffer_string);
    show_debug_message("Received: " + msg);
    
    // "id" is reserved — use "pid" instead
    var lastColon = string_last_pos(":", msg);
    var pid = string_copy(msg, 1, lastColon - 1);
    var coords = string_copy(msg, lastColon + 1, string_length(msg));
    
    var comma = string_pos(",", coords);
    var ox = real(string_copy(coords, 1, comma - 1));
    var oy = real(string_copy(coords, comma + 1, string_length(coords)));
    
    if (msg == "ack") {
        show_debug_message("Server acknowledged us!");
        exit;
    }
    
    var entry = ds_map_find_value(other_players, pid);
    if (is_undefined(entry)) {
        entry = array_create(2);
        ds_map_add(other_players, pid, entry);
    }
    entry[0] = ox;
    entry[1] = oy;
	
}
// telling server to exit(?)
if (ptype == 12){
	show_debug_message("Closing Server");
	game_end()
	exit;
}

*/