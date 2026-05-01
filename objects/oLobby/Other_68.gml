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
    global.my_pid = my_pid;

    if (is_host) {
        status_msg = "You are the host. Press SPACE to start.";
    } else {
        status_msg = "Waiting for host to start...";
    }

    show_debug_message("Got pid=" + string(my_pid) + " is_host=" + string(is_host));
    exit;
}

// Type 13 — player list update
// [u8:13][u8:count] then per player: [u16:pid][lpstr:username]
if (ptype == 13) {
    ds_map_clear(lobby_players);
    var _pcount = buffer_read(buf, buffer_u8);
    for (var _i = 0; _i < _pcount; _i++) {
        var _pid  = buffer_read(buf, buffer_u16);
        var _nlen = buffer_read(buf, buffer_u8);
        var _name = "";
        for (var _c = 0; _c < _nlen; _c++)
            _name += chr(buffer_read(buf, buffer_u8));
        ds_map_add(lobby_players, _pid, _name);
    }
    player_count = _pcount;
    show_debug_message("Player list updated: " + string(_pcount) + " players");
    exit;
}

// Type 3 — a player left
if (ptype == 3) {
    var left_pid = buffer_read(buf, buffer_u16);
    ds_map_delete(lobby_players, left_pid);
    show_debug_message("Player left: pid=" + string(left_pid));

    if (left_pid == 1 && !is_host) {
        show_debug_message("Host left — returning to lobby browser.");
        room_goto(rServerBrowser);
    }
    exit;
}

// Type 7 — host started match, go to loadout selection
if (ptype == 7) {
    global.socket          = socket;
    global.my_pid          = my_pid;
    global.going_to_match  = true;  // tell CleanUp not to disconnect
    room_goto(rm_loadout);
    exit;
}

// Type 8 — not enough players
if (ptype == 8) {
    status_msg = "Need at least 2 players!";
    exit;
}
