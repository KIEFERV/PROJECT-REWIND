/// Create_0 — oLobbyBrowser
///
/// Screen flow:
///   SCREEN_MODE   — player picks ONLINE or LAN
///   SCREEN_BROWSE — online lobby list
///   SCREEN_CREATE — create a new lobby (online)
///   SCREEN_LAN    — LAN lobby list / host tab

// ═══════════════════════════════════════════════════════════════════════════
//  CONFIGURATION — edit before running
// ═══════════════════════════════════════════════════════════════════════════
#macro VPS_IP           "206.189.192.97"
#macro LOBBY_PORT_NUM   8888
#macro GAME_PORT_NUM    7777
#macro DISC_PORT_NUM    7779
#macro MANAGER_PORT_NUM 9999
#macro SERVER_EXE       "C:\\Users\\Kiefer\\GameMakerProjects\\PROJECT-REWIND\\server\\server.exe"

// ═══════════════════════════════════════════════════════════════════════════
//  SCREEN IDs
// ═══════════════════════════════════════════════════════════════════════════
#macro SCREEN_MODE    0
#macro SCREEN_BROWSE  1
#macro SCREEN_CREATE  2
#macro SCREEN_LAN     3

// ─── Runtime state ────────────────────────────────────────────────────────
active_server_ip = VPS_IP;
is_lan_mode      = false;

// ─── Sockets ──────────────────────────────────────────────────────────────
lobby_socket   = network_create_socket(network_socket_udp);
game_socket    = -1;
disc_socket    = -1;
current_screen = SCREEN_MODE;

// ─── Connection globals ───────────────────────────────────────────────────
global.my_pid            = 0;
global.socket            = -1;
global.ip_address        = "";
global.port              = 0;
global.is_creating_lobby = false;

// ─── Browse state ─────────────────────────────────────────────────────────
lobby_list     = ds_list_create();
selected_index = 0;
status_msg     = "";
refresh_timer  = 0;
REFRESH_TICKS  = 3 * game_get_speed(gamespeed_fps);

// ─── LAN screen ───────────────────────────────────────────────────────────
lan_join_mode = true;
lan_ip_input  = "";    // joiner types the host's IP here

// ─── Join flow ────────────────────────────────────────────────────────────
join_pending       = false;
join_timeout       = 0;
JOIN_TIMEOUT_TICKS = 5 * game_get_speed(gamespeed_fps);

// ─── Password prompt ──────────────────────────────────────────────────────
pw_mode        = false;
pw_input       = "";
pw_pending_idx = -1;

// ─── Create lobby form ────────────────────────────────────────────────────
create_focus   = "name";
create_name    = "";
create_private = false;
create_pw      = "";

// ─── LAN screen ───────────────────────────────────────────────────────────
lan_join_mode = true;
lan_focus     = "name";

// ─── Local server launch polling (LAN) ────────────────────────────────────
launching         = false;
launch_poll_timer = 0;
LAUNCH_POLL_TICKS = game_get_speed(gamespeed_fps) / 4;
launch_timeout    = 0;
LAUNCH_TIMEOUT    = 10 * game_get_speed(gamespeed_fps);

// ─── Online create via manager ────────────────────────────────────────────
online_game_port = 0;
create_pending   = false;
create_timeout   = 0;
CREATE_TIMEOUT   = 5 * game_get_speed(gamespeed_fps);

// ═══════════════════════════════════════════════════════════════════════════
//  FUNCTIONS
// ═══════════════════════════════════════════════════════════════════════════

/// @desc djb2 password hash
function hash_password(_pw) {
    var _h = 5381;
    var _len = string_length(_pw);
    for (var _i = 1; _i <= _len; _i++)
        _h = ((_h * 33) & 0xFFFFFFFF) ^ ord(string_char_at(_pw, _i));
    var _hex = "";
    var _digits = "0123456789abcdef";
    for (var _b = 7; _b >= 0; _b--)
        _hex += string_char_at(_digits, ((_h >> (_b * 4)) & 0xF) + 1);
    return _hex;
}

/// @desc Request lobby list from Droplet
function request_lobby_list() {
    var _b = buffer_create(1, buffer_fixed, 1);
    buffer_write(_b, buffer_u8, 25);
    network_send_udp_raw(lobby_socket, active_server_ip, LOBBY_PORT_NUM, _b, 1);
    buffer_delete(_b);
}

/// @desc Send join request to Droplet lobby port
function send_join_request(_lobby_id, _pw_hash) {
    var _has_pw = (_pw_hash != "");
    var _b = buffer_create(64, buffer_grow, 1);
    buffer_write(_b, buffer_u8,  30);
    buffer_write(_b, buffer_u16, _lobby_id & 0xFFFF);
    buffer_write(_b, buffer_u16, (_lobby_id >> 16) & 0xFFFF);
    buffer_write(_b, buffer_u8,  _has_pw ? 1 : 0);
    if (_has_pw) {
        var _len = min(string_length(_pw_hash), 63);
        buffer_write(_b, buffer_u8, _len);
        for (var _i = 1; _i <= _len; _i++)
            buffer_write(_b, buffer_u8, ord(string_char_at(_pw_hash, _i)));
    }
    network_send_udp_raw(lobby_socket, active_server_ip, LOBBY_PORT_NUM, _b, buffer_tell(_b));
    buffer_delete(_b);
}

/// @desc Ping the game server with type-255 (no registration)
function ping_game_server() {
    if (game_socket < 0) exit;
    // LAN host pings localhost; online host pings VPS at assigned port
    var _ip   = is_lan_mode ? "127.0.0.1" : VPS_IP;
    var _port = (online_game_port > 0) ? online_game_port : GAME_PORT_NUM;
    var _b = buffer_create(1, buffer_fixed, 1);
    buffer_write(_b, buffer_u8, 255);
    network_send_udp_raw(game_socket, _ip, _port, _b, 1);
    buffer_delete(_b);
}

/// @desc Send CREATE_LOBBY_REQUEST (type 50) to the Droplet manager
function send_online_create_request() {
    var _pw_arg = "";
    if (create_private && create_pw != "")
        _pw_arg = hash_password(create_pw);

    var _safe_name = string_replace_all(create_name, "\"", "");
    if (string_trim(_safe_name) == "") _safe_name = "My Lobby";

    var _has_pw = (_pw_arg != "");
    var _b = buffer_create(128, buffer_grow, 1);
    buffer_write(_b, buffer_u8, 50);

    var _nlen = min(string_length(_safe_name), 63);
    buffer_write(_b, buffer_u8, _nlen);
    for (var _i = 1; _i <= _nlen; _i++)
        buffer_write(_b, buffer_u8, ord(string_char_at(_safe_name, _i)));

    buffer_write(_b, buffer_u8, _has_pw ? 1 : 0);
    if (_has_pw) {
        var _plen = min(string_length(_pw_arg), 63);
        buffer_write(_b, buffer_u8, _plen);
        for (var _i = 1; _i <= _plen; _i++)
            buffer_write(_b, buffer_u8, ord(string_char_at(_pw_arg, _i)));
    }

    network_send_udp_raw(lobby_socket, VPS_IP, MANAGER_PORT_NUM, _b, buffer_tell(_b));
    buffer_delete(_b);

    create_pending = true;
    create_timeout = CREATE_TIMEOUT;
    status_msg     = "Creating lobby on server...";
    show_debug_message("CREATE_REQUEST -> " + VPS_IP + ":" + string(MANAGER_PORT_NUM));
}

/// @desc Launch server.exe locally — LAN hosting only
/// Passes --lan so server registers with its auto-detected local IP in Supabase.
function launch_server_and_host() {
    var _args = "\"Local Game\" --lan";
    var _server_dir = filename_dir(SERVER_EXE) + "\\";
    execute_shell_simple(SERVER_EXE, _args, "open", 1, _server_dir);
    show_debug_message("Launched LAN server: " + _args);

    global.is_creating_lobby = true;
    global.ip_address        = "127.0.0.1";  // server runs locally
    global.port              = GAME_PORT_NUM;
    online_game_port         = 0;

    if (game_socket >= 0) network_destroy(game_socket);
    game_socket = network_create_socket(network_socket_udp);

    launching         = true;
    launch_poll_timer = 0;
    launch_timeout    = LAUNCH_TIMEOUT;
    status_msg        = "Starting server...";
}

/// @desc Connect directly to a LAN host by IP
function lan_direct_connect(_host_ip) {
    global.ip_address        = _host_ip;
    global.port              = GAME_PORT_NUM;
    global.is_creating_lobby = false;
    if (lobby_socket >= 0) { network_destroy(lobby_socket); lobby_socket = -1; }
    room_goto(rLobby);
}

/// @desc Free online lobby list
function cleanup_lobby_list() {
    if (!ds_exists(lobby_list, ds_type_list)) exit;
    for (var _i = 0; _i < ds_list_size(lobby_list); _i++) {
        var _m = ds_list_find_value(lobby_list, _i);
        if (ds_exists(_m, ds_type_map)) ds_map_destroy(_m);
    }
    ds_list_clear(lobby_list);
}

/// @desc Keyboard text input helper
function text_input_step(_str) {
    for (var _k = 32; _k <= 126; _k++) {
        if (keyboard_check_pressed(_k)) {
            var _ch = chr(_k);
            if (!keyboard_check(vk_shift)) _ch = string_lower(_ch);
            _str += _ch;
        }
    }
    if (keyboard_check_pressed(vk_backspace) && string_length(_str) > 0)
        _str = string_copy(_str, 1, string_length(_str) - 1);
    return _str;
}

show_debug_message("LobbyBrowser ready. VPS=" + VPS_IP);
