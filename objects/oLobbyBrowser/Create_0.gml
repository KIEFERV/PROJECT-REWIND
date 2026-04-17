/// Create_0 — oLobbyBrowser
///
/// Place this object in a room BEFORE rLobby.
/// The player sees a live lobby list, navigates with arrow keys,
/// optionally enters a password, then presses ENTER to join.
/// On join-approval the object sets global.ip_address / global.port
/// and transitions to rLobby exactly as before.

// ── DB server settings (must match lobby_db_server config) ───────────────────
global.db_ip   = "127.0.0.1";   // ← IP of the machine running lobby_db_server
global.db_port = 8888;

// ── Socket ───────────────────────────────────────────────────────────────────
db_socket = network_create_socket(network_socket_udp);

// ── Lobby list state ──────────────────────────────────────────────────────────
lobby_list     = ds_list_create();   // each element is a ds_map (one lobby)
status_msg     = "Fetching lobbies...";
selected_index = 0;

// ── Refresh timer ─────────────────────────────────────────────────────────────
refresh_timer  = 0;
REFRESH_TICKS  = 3 * game_get_speed(gamespeed_fps);  // re-request every 3 s

// ── Password prompt state ─────────────────────────────────────────────────────
pw_mode        = false;     // true = password input is open
pw_input       = "";        // raw text the player is typing
pw_pending_idx = -1;        // which lobby index we're trying to join

// ── Pending join-request (waiting for type-31 response) ──────────────────────
join_pending   = false;
join_timeout   = 0;
JOIN_TIMEOUT_TICKS = 5 * game_get_speed(gamespeed_fps);

// ── Simple djb2 hash (must match what the game server sends to the DB) ────────
// For a real game replace with a proper hash library; this is deterministic and
// consistent so the same password always hashes to the same string.
function hash_password(_pw) {
    var _h = 5381;
    var _len = string_length(_pw);
    for (var _i = 1; _i <= _len; _i++) {
        _h = ((_h * 33) & 0xFFFFFFFF) ^ ord(string_char_at(_pw, _i));
    }
    // Return as zero-padded 8-char hex
    var _hex = "";
    var _digits = "0123456789abcdef";
    for (var _b = 7; _b >= 0; _b--) {
        _hex += string_char_at(_digits, ((_h >> (_b * 4)) & 0xF) + 1);
    }
    return _hex;
}

// ── Send list request (type 25) ───────────────────────────────────────────────
function db_request_list() {
    var _buf = buffer_create(1, buffer_fixed, 1);
    buffer_write(_buf, buffer_u8, 25);
    network_send_udp_raw(db_socket, global.db_ip, global.db_port, _buf, 1);
    buffer_delete(_buf);
}

// ── Send join request (type 30) ───────────────────────────────────────────────
// _lobby_id   : u32 lobby id
// _pw_hash    : "" if no password, otherwise the hash string
function db_send_join(_lobby_id, _pw_hash) {
    var _has_pw = (_pw_hash != "");
    var _sz = 6 + (_has_pw ? (1 + string_length(_pw_hash)) : 0);
    var _buf = buffer_create(_sz, buffer_grow, 1);
    buffer_write(_buf, buffer_u8,  30);          // type
    buffer_write(_buf, buffer_u16, _lobby_id & 0xFFFF);       // lobby_id lo
    buffer_write(_buf, buffer_u16, (_lobby_id >> 16) & 0xFFFF); // lobby_id hi
    buffer_write(_buf, buffer_u8,  _has_pw ? 1 : 0);
    if (_has_pw) {
        var _len = min(string_length(_pw_hash), 63);
        buffer_write(_buf, buffer_u8, _len);
        for (var _i = 1; _i <= _len; _i++) {
            buffer_write(_buf, buffer_u8, ord(string_char_at(_pw_hash, _i)));
        }
    }
    network_send_udp_raw(db_socket, global.db_ip, global.db_port,
                         _buf, buffer_tell(_buf));
    buffer_delete(_buf);
}

// ── Free all ds_maps in the lobby list ────────────────────────────────────────
function cleanup_lobby_list() {
    for (var _i = 0; _i < ds_list_size(lobby_list); _i++) {
        var _m = ds_list_find_value(lobby_list, _i);
        if (ds_exists(_m, ds_type_map)) ds_map_destroy(_m);
    }
    ds_list_clear(lobby_list);
}

// ── Initial fetch ─────────────────────────────────────────────────────────────
db_request_list();

show_debug_message("LobbyBrowser created. DB=" +
    global.db_ip + ":" + string(global.db_port));
