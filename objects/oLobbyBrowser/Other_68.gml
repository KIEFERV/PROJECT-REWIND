/// Other_68 (Async - Networking) — oLobbyBrowser

if (async_load[? "type"] != network_type_data) exit;

var _buf    = async_load[? "buffer"];
var _sockid = async_load[? "id"];
buffer_seek(_buf, buffer_seek_start, 0);
var _ptype = buffer_read(_buf, buffer_u8);

show_debug_message("LobbyBrowser async: ptype=" + string(_ptype)
    + " socket=" + string(_sockid)
    + " lobby=" + string(lobby_socket));

// ════════════════════════════════════════════════════════════════════════════
//  type 255 — ping response — server is ready, transition to rLobby as host
// ════════════════════════════════════════════════════════════════════════════
if (_ptype == 255 && launching) {
    show_debug_message("Server ping response — server is ready.");
    launching = false;

    network_destroy(game_socket);  game_socket  = -1;
    network_destroy(lobby_socket); lobby_socket = -1;

    global.is_creating_lobby = false;
    room_goto(rLobby);
    exit;
}

// ════════════════════════════════════════════════════════════════════════════
//  type 51 — CREATE_LOBBY_ACK from manager
//  [u8:51][u8:result][u16:game_port if result=0]
// ════════════════════════════════════════════════════════════════════════════
if (_ptype == 51 && create_pending) {
    create_pending = false;
    var _result = buffer_read(_buf, buffer_u8);

    if (_result == 0) {
        var _port = buffer_read(_buf, buffer_u16);
        show_debug_message("CREATE_ACK: server spawned on port " + string(_port));

        online_game_port         = _port;
        global.is_creating_lobby = true;
        global.ip_address        = VPS_IP;
        global.port              = _port;

        if (game_socket >= 0) network_destroy(game_socket);
        game_socket = network_create_socket(network_socket_udp);

        launching         = true;
        launch_poll_timer = 0;
        launch_timeout    = LAUNCH_TIMEOUT;
        status_msg        = "Waiting for server to start...";
    } else {
        status_msg     = "Server is full — no lobbies available. Try again later.";
        current_screen = SCREEN_BROWSE;
    }
    exit;
}

// ════════════════════════════════════════════════════════════════════════════
//  type 26 — LIST_RESPONSE
//  per entry: [u32:id][lpstr:name][lpstr:host_ip][u16:port]
//             [u8:current][u8:max][u8:has_password][u8:is_active][u8:is_lan]
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

        // consume host_ip
        var _iplen = buffer_read(_buf, buffer_u8);
        for (var _c = 0; _c < _iplen; _c++) buffer_read(_buf, buffer_u8);

        // consume port, read stats
        buffer_read(_buf, buffer_u16);
        var _current   = buffer_read(_buf, buffer_u8);
        var _max       = buffer_read(_buf, buffer_u8);
        var _has_pw    = buffer_read(_buf, buffer_u8);
        var _is_active = buffer_read(_buf, buffer_u8);
        var _is_lan    = buffer_read(_buf, buffer_u8);

        // Skip LAN lobbies — online only
        if (_is_lan) continue;

        var _entry = ds_map_create();
        ds_map_add(_entry, "id",           _id);
        ds_map_add(_entry, "name",         _name);
        ds_map_add(_entry, "current",      _current);
        ds_map_add(_entry, "max",          _max);
        ds_map_add(_entry, "has_password", _has_pw);
        ds_list_add(lobby_list, _entry);
    }

    selected_index = clamp(selected_index, 0, max(0, ds_list_size(lobby_list) - 1));

    if (ds_list_size(lobby_list) == 0)
        status_msg = "No lobbies found.  C = create   R = refresh";
    else
        status_msg = "Up/Down select   ENTER join   C create   R refresh";

    show_debug_message("Lobby list: " + string(ds_list_size(lobby_list)) + " entries.");
    exit;
}

// ════════════════════════════════════════════════════════════════════════════
//  type 31 — JOIN_RESPONSE
//  [u8:31][u8:result][lpstr:host_ip][u16:port] if result=0
// ════════════════════════════════════════════════════════════════════════════
if (_ptype == 31) {
    join_pending = false;
    var _result = buffer_read(_buf, buffer_u8);

    if (_result == 0) {
        var _iplen = buffer_read(_buf, buffer_u8);
        var _ip = "";
        for (var _c = 0; _c < _iplen; _c++)
            _ip += chr(buffer_read(_buf, buffer_u8));
        var _port = buffer_read(_buf, buffer_u16);

        global.ip_address        = _ip;
        global.port              = _port;
        global.is_creating_lobby = false;
        show_debug_message("Join approved -> " + _ip + ":" + string(_port));

        network_destroy(lobby_socket);
        lobby_socket = -1;
        room_goto(rLobby);

    } else if (_result == 1) {
        status_msg = "Incorrect password.";
    } else {
        status_msg = "That lobby no longer exists.";
        request_lobby_list();
    }
    exit;
}
