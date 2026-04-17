/// Other_68 (Async – Networking) — oLobbyBrowser

if (async_load[? "type"] != network_type_data) exit;

var _buf = async_load[? "buffer"];
buffer_seek(_buf, buffer_seek_start, 0);
var _ptype = buffer_read(_buf, buffer_u8);

// ════════════════════════════════════════════════════════════════════════════
//  type 26 — LIST_RESPONSE
//  [u8:26][u8:count]
//  per lobby: [u32:id][lpstr:name][lpstr:host_ip][u16:port]
//             [u8:current][u8:max][u8:has_password][u8:is_active]
// ════════════════════════════════════════════════════════════════════════════
if (_ptype == 26) {
    cleanup_lobby_list();

    var _count = buffer_read(_buf, buffer_u8);
    for (var _i = 0; _i < _count; _i++) {

        // lobby_id as two u16s (little-endian u32)
        var _id_lo = buffer_read(_buf, buffer_u16);
        var _id_hi = buffer_read(_buf, buffer_u16);
        var _id    = _id_lo | (_id_hi << 16);

        // name (length-prefixed string)
        var _name_len = buffer_read(_buf, buffer_u8);
        var _name = "";
        for (var _c = 0; _c < _name_len; _c++)
            _name += chr(buffer_read(_buf, buffer_u8));

        // host_ip (length-prefixed string)
        var _ip_len = buffer_read(_buf, buffer_u8);
        var _ip = "";
        for (var _c = 0; _c < _ip_len; _c++)
            _ip += chr(buffer_read(_buf, buffer_u8));

        var _port       = buffer_read(_buf, buffer_u16);
        var _current    = buffer_read(_buf, buffer_u8);
        var _max        = buffer_read(_buf, buffer_u8);
        var _has_pw     = buffer_read(_buf, buffer_u8);
        var _is_active  = buffer_read(_buf, buffer_u8);

        var _entry = ds_map_create();
        ds_map_add(_entry, "id",           _id);
        ds_map_add(_entry, "name",         _name);
        ds_map_add(_entry, "host_ip",      _ip);
        ds_map_add(_entry, "host_port",    _port);
        ds_map_add(_entry, "current",      _current);
        ds_map_add(_entry, "max",          _max);
        ds_map_add(_entry, "has_password", _has_pw);
        ds_map_add(_entry, "is_active",    _is_active);
        ds_list_add(lobby_list, _entry);
    }

    selected_index = clamp(selected_index, 0, max(0, ds_list_size(lobby_list) - 1));

    if (ds_list_size(lobby_list) == 0)
        status_msg = "No lobbies available. Press R to refresh.";
    else
        status_msg = "↑↓ select   ENTER join   R refresh";

    show_debug_message("Received " + string(_count) + " lobbies.");
    exit;
}

// ════════════════════════════════════════════════════════════════════════════
//  type 31 — JOIN_RESPONSE
//  [u8:31][u8:result]
//  if result=0: [lpstr:host_ip][u16:host_port]
// ════════════════════════════════════════════════════════════════════════════
if (_ptype == 31) {
    join_pending = false;
    var _result = buffer_read(_buf, buffer_u8);

    if (_result == 0) {
        // Approved — read the game server address
        var _ip_len = buffer_read(_buf, buffer_u8);
        var _ip = "";
        for (var _c = 0; _c < _ip_len; _c++)
            _ip += chr(buffer_read(_buf, buffer_u8));
        var _port = buffer_read(_buf, buffer_u16);

        global.ip_address = _ip;
        global.port       = _port;
        show_debug_message("Join approved → " + _ip + ":" + string(_port));

        // Clean up before transitioning
        network_destroy(db_socket);
        cleanup_lobby_list();
        ds_list_destroy(lobby_list);

        room_goto(rLobby);   // your existing lobby room

    } else if (_result == 1) {
        status_msg = "Wrong password. Try again.";
        show_debug_message("Join denied: wrong password.");

    } else if (_result == 2) {
        status_msg = "Lobby no longer exists.";
        db_request_list();  // refresh in case it disappeared
        show_debug_message("Join denied: lobby not found.");
    }
    exit;
}
