/// Create_0 — oLobbyBrowser
///
/// Connects to the merged game+lobby server.
/// The server handles both game traffic (port 7777) and lobby browsing (port 8888).
/// There is no longer a separate lobby_db_server process.
///
/// ─── SETUP ────────────────────────────────────────────────────────────────
///   • Set SERVER_IP to the public IP of your VPS (or 127.0.0.1 for local)
///   • Set SERVER_EXE to the full path to server.exe (local hosting only)
///   • Set MY_PUBLIC_IP to this machine's public IP (local hosting only)

// ═══════════════════════════════════════════════════════════════════════════
//  CONFIGURATION
// ═══════════════════════════════════════════════════════════════════════════

// IP of the machine running server.exe
// For a VPS: the VPS public IP,  e.g. "203.0.113.10"
// For local: "127.0.0.1"
#macro SERVER_IP     "127.0.0.1"

// Lobby port (where list requests and join requests go)
#macro LOBBY_PORT_NUM  8888

// Game port (where actual gameplay traffic goes)
#macro GAME_PORT_NUM   7777

// Full absolute path to server.exe (only used when hosting locally)
#macro SERVER_EXE    "C:\\Users\\Kiefer\\GameMakerProjects\\PROJECT-REWIND\\server\\server.exe"

// This machine's public/LAN IP — passed to server.exe so other clients
// can find this lobby. Only used when hosting locally.
#macro MY_PUBLIC_IP  "127.0.0.1"

// ═══════════════════════════════════════════════════════════════════════════
//  SCREEN IDs
// ═══════════════════════════════════════════════════════════════════════════
#macro SCREEN_BROWSE  0
#macro SCREEN_CREATE  1

// ─── Sockets ──────────────────────────────────────────────────────────────
// lobby_socket — talks to server lobby port (8888) for browse/join
// game_socket  — temporary poll socket used only during server launch
lobby_socket   = network_create_socket(network_socket_udp);
game_socket    = -1;
current_screen = SCREEN_BROWSE;

// Reset connection globals
global.my_pid            = 0;
global.socket            = -1;
global.ip_address        = "";
global.port              = 0;
global.is_creating_lobby = false;

// ─── Browse state ─────────────────────────────────────────────────────────
lobby_list     = ds_list_create();
selected_index = 0;
status_msg     = "Fetching lobbies...";
refresh_timer  = 0;
REFRESH_TICKS  = 3 * game_get_speed(gamespeed_fps);

// ─── Join flow ────────────────────────────────────────────────────────────
join_pending       = false;
join_timeout       = 0;
JOIN_TIMEOUT_TICKS = 5 * game_get_speed(gamespeed_fps);

// ─── Password prompt (joining private lobby) ──────────────────────────────
pw_mode        = false;
pw_input       = "";
pw_pending_idx = -1;

// ─── Create lobby form ────────────────────────────────────────────────────
create_focus   = "name";
create_name    = "";
create_private = false;
create_pw      = "";

// ─── Server launch / poll state ───────────────────────────────────────────
launching         = false;
launch_poll_timer = 0;
LAUNCH_POLL_TICKS = game_get_speed(gamespeed_fps) / 4;
launch_timeout    = 0;
LAUNCH_TIMEOUT    = 10 * game_get_speed(gamespeed_fps);

// ─── djb2 hash ────────────────────────────────────────────────────────────
function hash_password(_pw) {
    var _h   = 5381;
    var _len = string_length(_pw);
    for (var _i = 1; _i <= _len; _i++)
        _h = ((_h * 33) & 0xFFFFFFFF) ^ ord(string_char_at(_pw, _i));
    var _hex    = "";
    var _digits = "0123456789abcdef";
    for (var _b = 7; _b >= 0; _b--)
        _hex += string_char_at(_digits, ((_h >> (_b * 4)) & 0xF) + 1);
    return _hex;
}

// ─── Send lobby list request (type 25) to lobby port ──────────────────────
function request_lobby_list() {
    var _b = buffer_create(1, buffer_fixed, 1);
    buffer_write(_b, buffer_u8, 25);
    network_send_udp_raw(lobby_socket, SERVER_IP, LOBBY_PORT_NUM, _b, 1);
    buffer_delete(_b);
}

// ─── Send join request (type 30) to lobby port ────────────────────────────
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
    network_send_udp_raw(lobby_socket, SERVER_IP, LOBBY_PORT_NUM, _b, buffer_tell(_b));
    buffer_delete(_b);
}

// ─── Ping game server (type 255) — confirms it is alive without registering
function ping_game_server() {
    if (game_socket < 0) exit;
    var _b = buffer_create(1, buffer_fixed, 1);
    buffer_write(_b, buffer_u8, 255);
    network_send_udp_raw(game_socket, SERVER_IP, GAME_PORT_NUM, _b, 1);
    buffer_delete(_b);
}

// ─── Launch server.exe locally and poll until ready ───────────────────────
function launch_server_and_host() {
    var _pw_arg    = "";
    if (create_private && create_pw != "")
        _pw_arg = hash_password(create_pw);

    var _safe_name = string_replace_all(create_name, "\"", "");
    if (_safe_name == "") _safe_name = "My Lobby";

    // server.exe now takes: <lobby_name> <public_ip> [password_hash]
    // (no db_ip arg — Supabase URL is compiled into the server)
    var _args = "\"" + _safe_name + "\" " + MY_PUBLIC_IP;
    if (_pw_arg != "") _args += " " + _pw_arg;

    var _server_dir = filename_dir(SERVER_EXE) + "\\";
    execute_shell_simple(SERVER_EXE, _args, "open", 1, _server_dir);
    show_debug_message("Launched: " + SERVER_EXE + " " + _args);

    global.is_creating_lobby = true;
    global.ip_address        = SERVER_IP;
    global.port              = GAME_PORT_NUM;

    if (game_socket >= 0) network_destroy(game_socket);
    game_socket = network_create_socket(network_socket_udp);

    launching         = true;
    launch_poll_timer = 0;
    launch_timeout    = LAUNCH_TIMEOUT;
    status_msg        = "Starting server...";
}

// ─── Free lobby list ds_maps ──────────────────────────────────────────────
function cleanup_lobby_list() {
    if (!ds_exists(lobby_list, ds_type_list)) exit;
    for (var _i = 0; _i < ds_list_size(lobby_list); _i++) {
        var _m = ds_list_find_value(lobby_list, _i);
        if (ds_exists(_m, ds_type_map)) ds_map_destroy(_m);
    }
    ds_list_clear(lobby_list);
}

// ─── Text input helper ────────────────────────────────────────────────────
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

// ─── Initial fetch ────────────────────────────────────────────────────────
request_lobby_list();
show_debug_message("LobbyBrowser ready. Server=" + SERVER_IP + ":" + string(LOBBY_PORT_NUM));
