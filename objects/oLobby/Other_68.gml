/// Other_68 (Async - Networking) — oLobby

show_debug_message("Lobby async fired! type=" + string(async_load[? "type"]));
if (async_load[? "type"] != network_type_data) exit;

var buf = async_load[? "buffer"];
buffer_seek(buf, buffer_seek_start, 0);
var ptype = buffer_read(buf, buffer_u8);

// Type 2 = server assigned us a pid
if (ptype == 2) {
    my_pid       = buffer_read(buf, buffer_u16);
    player_count = my_pid;

    // Only update is_host from the pid if we don't already know we're the host.
    // global.is_creating_lobby was already cleared in Create, so use my_pid==1
    // as the definitive check — but never downgrade is_host from true to false
    // if it was set in Create (host arrives before any other client so will
    // always be pid=1 now that the poll probe no longer consumes a slot).
    is_host = (my_pid == 1);

    if (is_host) {
        status_msg = "You are the host. Press SPACE to start.";
    } else {
        status_msg = "Waiting for host to start...";
    }

    show_debug_message("Got pid=" + string(my_pid) + " is_host=" + string(is_host));
    exit;
}

// Type 7 = match is starting
if (ptype == 7) {
    global.socket = socket;
    global.my_pid = my_pid;
    room_goto(rMovementTesting);
    exit;
}

// Type 8 = not enough players
if (ptype == 8) {
    status_msg = "Need at least 2 players!";
    exit;
}
