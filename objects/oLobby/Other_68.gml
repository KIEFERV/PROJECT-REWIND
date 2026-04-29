/// Other_68 (Async - Networking) — oLobby

if (async_load[? "type"] != network_type_data) exit;

var buf = async_load[? "buffer"];
buffer_seek(buf, buffer_seek_start, 0);
var ptype = buffer_read(buf, buffer_u8);

// Type 2 — server assigned us a pid
if (ptype == 2) {
    my_pid        = buffer_read(buf, buffer_u16);
    player_count  = my_pid;
    is_host       = (my_pid == 1);
    global.my_pid = my_pid;  // store so oPlayerHitbox can use it for spawn

    if (is_host) {
        status_msg = "You are the host. Press SPACE to start.";
    } else {
        status_msg = "Waiting for host to start...";
    }

    show_debug_message("Got pid=" + string(my_pid) + " is_host=" + string(is_host));
    exit;
}

// Type 3 — a player left
if (ptype == 3) {
    var left_pid = buffer_read(buf, buffer_u16);
    show_debug_message("Player left: pid=" + string(left_pid));

    // If the host left, return everyone to the lobby browser
    if (left_pid == 1 && !is_host) {
        show_debug_message("Host left — returning to lobby browser.");
        room_goto(rLobbyBrowser);  // ← replace rLobbyBrowser with your actual room name
    }
    exit;
}

// Type 7 — match is starting
if (ptype == 7) {
    global.socket = socket;
    global.my_pid = my_pid;
    room_goto(rMovementTesting);
    exit;
}

// Type 8 — not enough players
if (ptype == 8) {
    status_msg = "Need at least 2 players!";
    exit;
}
