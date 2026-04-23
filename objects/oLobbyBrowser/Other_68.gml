/// Other_68 (Async - Networking) — oLobbyBrowser

if (async_load[? "type"] != network_type_data) exit;

var _buf    = async_load[? "buffer"];
var _sockid = async_load[? "id"];   // which socket received this packet
buffer_seek(_buf, buffer_seek_start, 0);
var _ptype = buffer_read(_buf, buffer_u8);

// Debug — log all incoming packets
show_debug_message("LobbyBrowser async: ptype=" + string(_ptype)
    + " socket=" + string(_sockid)
    + " lobby=" + string(lobby_socket)
    + " disc=" + string(disc_socket));

// ════════════════════════════════════════════════════════════════════════════
//  type 40 — LAN DISCOVERY broadcast from a host on the local network
//  [u8:40][lpstr:lobby_name][u8:current_players][u8:max_players][u8:has_pw]
//  The sender's IP is extracted from async_load and used as the host address.
// ════════════════════════════════════════════════════════════════════════════
if (_ptype == 40) {
    // Read lobby info
    var _name_len = buffer_read(_buf, buffer_u8);
    var _name = "";
    for (var _c = 0; _c < _name_len; _c++)
        _name += chr(buffer_read(_buf, buffer_u8));
    var _cur   = buffer_read(_buf, buffer_u8);
    var _max   = buffer_read(_buf, buffer_u8);
    var _has_pw = buffer_read(_buf, buffer_u8);

    // Get sender IP from async_load
    var _ip = async_load[? "ip"];

    // Use ip as the map key
    var _map_key = _ip;

    // Create or update the host entry
    if (!ds_map_exists(lan_hosts, _map_key)) {
        var _entry = ds_map_create();
        ds_map_add(lan_hosts, _map_key, _entry);
    }
    var _host_entry = lan_hosts[? _map_key];
    _host_entry[? "ip"]      = _ip;
    _host_entry[? "name"]    = _name;
    _host_entry[? "current"] = _cur;
    _host_entry[? "max"]     = _max;
    _host_entry[? "has_pw"]  = _has_pw;

    // Stamp the last-seen time
    lan_host_times[? _map_key] = current_time;

    show_debug_message("Discovered LAN host: " + _name + " at " + _ip);
    exit;
}

// ════════════════════════════════════════════════════════════════════════════
//  type 255 — PING response from game server
//  Server echoes 255 back without registering a player slot.
//  This confirms server.exe is alive. We destroy the poll socket and
//  transition — oLobby will create its own socket and get pid=1 cleanly.
// ════════════════════════════════════════════════════════════════════════════
if (_ptype == 255 && launching) {
    show_debug_message("Server ping response received — server is ready.");

    launching = false;

    network_destroy(game_socket);
    game_socket = -1;

    network_destroy(lobby_socket);
    lobby_socket = -1;

    // is_creating_lobby was set true when CREATE_ACK arrived.
    // Clear it now — is_host will be set authoritatively from the pid response.
    global.is_creating_lobby = false;

    room_goto(rLobby);
    exit;
}


// ════════════════════════════════════════════════════════════════════════════
//  type 51 — CREATE_LOBBY_ACK from Droplet manager
//  [u8:51][u8:result][u16:game_port if result=0]
//  result 0 = ok — server spawned on game_port
//  result 1 = no ports available
// ════════════════════════════════════════════════════════════════════════════
if (_ptype == 51 && create_pending) {
    create_pending = false;
    var _result = buffer_read(_buf, buffer_u8);

    if (_result == 0) {
        // Manager assigned us a port — read it
        var _port = buffer_read(_buf, buffer_u16);
        show_debug_message("CREATE_ACK: server spawned on port " + string(_port));

        online_game_port         = _port;
        global.is_creating_lobby = true;
        global.ip_address        = VPS_IP;
        global.port              = _port;

        // Poll the new server instance until it responds
        if (game_socket >= 0) network_destroy(game_socket);
        game_socket = network_create_socket(network_socket_udp);

        launching         = true;
        launch_poll_timer = 0;
        launch_timeout    = LAUNCH_TIMEOUT;
        status_msg        = "Waiting for server to start...";

    } else {
        status_msg     = "Server is full — no lobbies available. Try again later.";
        current_screen = SCREEN_BROWSE;
        show_debug_message("CREATE_ACK: no ports available");
    }
    exit;
}

// ════════════════════════════════════════════════════════════════════════════
//  type 26 — LIST_RESPONSE from DB server
//  [u8:26][u8:count]
//  per lobby: [u32:id as 2xu16][lpstr:name][lpstr:host_ip][u16:port]
//             [u8:current][u8:max][u8:has_password][u8:is_active]
//  host_ip and port are consumed but not stored — never shown to the player.
// ════════════════════════════════════════════════════════════════════════════
if (_ptype == 26) {
    cleanup_lobby_list();

    var _count = buffer_read(_buf, buffer_u8);
    for (var _i = 0; _i < _count; _i++) {
        var _id_lo = buffer_read(_buf, buffer_u16);
        var _id_hi = buffer_read(_buf, buffer_u16);
        var _id    = _id_lo | (_id_hi << 16);

        var _nlen = buffer_read(_buf, buffer_u8);
        var _name = "";
        for (var _c = 0; _c < _nlen; _c++)
            _name += chr(buffer_read(_buf, buffer_u8));

        // host_ip — consumed, discarded
        var _iplen = buffer_read(_buf, buffer_u8);
        for (var _c = 0; _c < _iplen; _c++)
            buffer_read(_buf, buffer_u8);

        // host_port — consumed, discarded
        buffer_read(_buf, buffer_u16);

        var _current   = buffer_read(_buf, buffer_u8);
        var _max       = buffer_read(_buf, buffer_u8);
        var _has_pw    = buffer_read(_buf, buffer_u8);
        var _is_active = buffer_read(_buf, buffer_u8);

        var _entry = ds_map_create();
        ds_map_add(_entry, "id",           _id);
        ds_map_add(_entry, "name",         _name);
        ds_map_add(_entry, "current",      _current);
        ds_map_add(_entry, "max",          _max);
        ds_map_add(_entry, "has_password", _has_pw);
        ds_map_add(_entry, "is_active",    _is_active);
        ds_list_add(lobby_list, _entry);
    }

    selected_index = clamp(selected_index, 0, max(0, ds_list_size(lobby_list) - 1));

    if (ds_list_size(lobby_list) == 0)
        status_msg = "No lobbies found.  C = create one   R = refresh";
    else
        status_msg = "Up/Down select   ENTER join   C create   R refresh";

    show_debug_message("Lobby list: " + string(_count) + " entries.");
    exit;
}

// ════════════════════════════════════════════════════════════════════════════
//  type 31 — JOIN_RESPONSE from DB server
//  [u8:31][u8:result]
//  0 = approved -> [lpstr:host_ip][u16:host_port]
//  1 = wrong password
//  2 = lobby not found
// ════════════════════════════════════════════════════════════════════════════
if (_ptype == 31) {
    join_pending = false;
    var _result = buffer_read(_buf, buffer_u8);

    if (_result == 0) {
        var _iplen = buffer_read(_buf, buffer_u8);
        var _ip    = "";
        for (var _c = 0; _c < _iplen; _c++)
            _ip += chr(buffer_read(_buf, buffer_u8));
        var _port = buffer_read(_buf, buffer_u16);

        global.ip_address        = _ip;
        global.port              = _port;
        global.is_creating_lobby = false;  // joiner is never the host
        show_debug_message("Join approved -> " + _ip + ":" + string(_port));

        network_destroy(lobby_socket);
        lobby_socket = -1;

        room_goto(rLobby);

    } else if (_result == 1) {
        status_msg = "Incorrect password. Please try again.";
    } else if (_result == 2) {
        status_msg = "That lobby no longer exists.";
        request_lobby_list();
    }
    exit;
}
