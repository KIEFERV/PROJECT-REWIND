show_debug_message("Lobby async fired! type=" + string(async_load[? "type"]));
if (async_load[? "type"] != network_type_data) exit;

var buf = async_load[? "buffer"];
buffer_seek(buf, buffer_seek_start, 0);
var ptype = buffer_read(buf, buffer_u8);

// Type 2 = server assigned us a pid
if (ptype == 2) {
    my_pid = buffer_read(buf, buffer_u16);
    is_host = (my_pid == 1);
    player_count = my_pid;  // approximate — pid count = player count
    
    if (is_host) {
        status_msg = "You are the host. Press SPACE to start.";
    } else {
        status_msg = "Waiting for host to start...";
    }
    exit;
}

// Type 7 = match is starting
if (ptype == 7) {
    // Store socket so the game room can use it
    global.socket = socket;
    global.my_pid = my_pid;
    room_goto(rMovementTesting);  // replace with your actual game room name
    exit;
}

// Type 8 = not enough players
if (ptype == 8) {
    status_msg = "Need at least 2 players!";
    exit;
}