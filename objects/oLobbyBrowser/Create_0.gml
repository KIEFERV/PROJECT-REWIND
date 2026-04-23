/// Create_0 — oLobbyBrowser
///
/// Screen flow:
///   SCREEN_MODE   — player picks ONLINE or LAN
///   SCREEN_BROWSE — lobby list (online only)
///   SCREEN_CREATE — create a new lobby (online or LAN)
///   SCREEN_LAN    — LAN quick-connect (enter host IP, join directly)

// ═══════════════════════════════════════════════════════════════════════════
//  CONFIGURATION
// ═══════════════════════════════════════════════════════════════════════════

// VPS public IP
#macro VPS_IP        "206.189.192.97"

// Ports
#macro LOBBY_PORT_NUM  8888
#macro GAME_PORT_NUM   7777
#macro DISC_PORT_NUM   7779   // LAN discovery broadcast port

// Full path to server.exe (used when hosting locally — LAN or online from this PC)
#macro SERVER_EXE    "C:\\Users\\Kiefer\\GameMakerProjects\\PROJECT-REWIND\\server\\server.exe"

// No MY_LAN_IP or MY_PUBLIC_IP needed — server.exe auto-detects its own IP.

// ═══════════════════════════════════════════════════════════════════════════
//  SCREEN IDs
// ═══════════════════════════════════════════════════════════════════════════
#macro SCREEN_MODE    0   // online vs LAN selection
#macro SCREEN_BROWSE  1   // online lobby list
#macro SCREEN_CREATE  2   // create lobby form
#macro SCREEN_LAN     3   // LAN direct connect

// ─── Active connection target ─────────────────────────────────────────────
active_server_ip   = VPS_IP;        // where lobby requests go
is_lan_mode        = false;

// ─── Sockets ──────────────────────────────────────────────────────────────
lobby_socket   = network_create_socket(network_socket_udp);
game_socket    = -1;
// Discovery socket — listens for type-40 broadcasts from LAN hosts
// Created when entering LAN mode, destroyed when leaving
disc_socket    = -1;
current_screen = SCREEN_MODE;

// Reset connection globals
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

// ─── LAN discovered hosts ─────────────────────────────────────────────────
// ds_map keyed on "ip:port" string, value is a ds_map with host info.
// Entries expire after 3 seconds of no broadcast.
lan_hosts         = ds_map_create();
lan_host_times    = ds_map_create();  // key -> last-seen timestamp (ms)
LAN_HOST_EXPIRE   = 3000;             // ms before removing a silent host
lan_selected      = 0;                // selected index in the discovered list

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

// ─── LAN screen state ────────────────────────────────────────────────────
lan_join_mode  = true;   // true = join tab, false = host tab
lan_focus      = "name"; // field focus on host tab

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

// ─── Fetch lobby list from active server ──────────────────────────────────
function request_lobby_list() {
    var _b = buffer_create(1, buffer_fixed, 1);
    buffer_write(_b, buffer_u8, 25);
    network_send_udp_raw(lobby_socket, active_server_ip, LOBBY_PORT_NUM, _b, 1);
    buffer_delete(_b);
}

// ─── Send join request to active server ───────────────────────────────────
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

// ─── Ping game server (type 255) — readiness check ────────────────────────
function ping_game_server() {
    if (game_socket < 0) exit;
    var _b = buffer_create(1, buffer_fixed, 1);
    buffer_write(_b, buffer_u8, 255);
    network_send_udp_raw(game_socket, active_server_ip, GAME_PORT_NUM, _b, 1);
    buffer_delete(_b);
}

// ─── Launch server.exe and begin polling ──────────────────────────────────
function launch_server_and_host() {
    var _pw_arg = "";
    if (create_private && create_pw != "")
        _pw_arg = hash_password(create_pw);

    var _safe_name = string_replace_all(create_name, "\"", "");
    if (_safe_name == "") _safe_name = "My Lobby";

    // server.exe detects its own IP automatically via get_lan_ip():
    //   On the Droplet  → returns the public IP  (e.g. 206.x.x.x)
    //   On a home PC    → returns the LAN IP     (e.g. 192.168.x.x)
    // No need to pass it — just lobby name and optional password hash.
    var _args = "\"" + _safe_name + "\"";
    if (_pw_arg != "") _args += " " + _pw_arg;

    var _server_dir = filename_dir(SERVER_EXE) + "\\";
    execute_shell_simple(SERVER_EXE, _args, "open", 1, _server_dir);
    show_debug_message("Launched: " + SERVER_EXE + " " + _args);

    global.is_creating_lobby = true;
    global.ip_address        = active_server_ip;
    global.port              = GAME_PORT_NUM;

    if (game_socket >= 0) network_destroy(game_socket);
    game_socket = network_create_socket(network_socket_udp);

    launching         = true;
    launch_poll_timer = 0;
    launch_timeout    = LAUNCH_TIMEOUT;
    status_msg        = "Starting server...";
}

// ─── Open/close the LAN discovery socket ──────────────────────────────────
function open_disc_socket() {
    if (disc_socket >= 0) network_destroy(disc_socket);
    disc_socket = network_create_socket(network_socket_udp);
    // Bind to the discovery port so we receive broadcasts
    network_set_config(network_config_connect_timeout, 1000);
    // GML UDP sockets don't support explicit bind to a port in raw mode,
    // so we use network_create_socket_ext to bind to DISC_PORT_NUM
    network_destroy(disc_socket);
    disc_socket = network_create_socket_ext(network_socket_udp, DISC_PORT_NUM);
    show_debug_message("Discovery socket opened on port " + string(DISC_PORT_NUM));
}

function close_disc_socket() {
    if (disc_socket >= 0) {
        network_destroy(disc_socket);
        disc_socket = -1;
    }
    // Clear the host list
    var _key = ds_map_find_first(lan_hosts);
    while (!is_undefined(_key)) {
        var _entry = lan_hosts[? _key];
        if (ds_exists(_entry, ds_type_map)) ds_map_destroy(_entry);
        _key = ds_map_find_next(lan_hosts, _key);
    }
    ds_map_clear(lan_hosts);
    ds_map_clear(lan_host_times);
}

// ─── Direct LAN connect to a discovered host ─────────────────────────────
function lan_direct_connect(_host_ip) {
    global.ip_address        = _host_ip;
    global.port              = GAME_PORT_NUM;
    global.is_creating_lobby = false;

    close_disc_socket();
    network_destroy(lobby_socket);
    lobby_socket = -1;

    room_goto(rLobby);
}

// ─── Free lobby list ──────────────────────────────────────────────────────
function cleanup_lobby_list() {
    if (!ds_exists(lobby_list, ds_type_list)) exit;
    for (var _i = 0; _i < ds_list_size(lobby_list); _i++) {
        var _m = ds_list_find_value(lobby_list, _i);
        if (ds_exists(_m, ds_type_map)) ds_map_destroy(_m);
    }
    ds_list_clear(lobby_list);
}
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

show_debug_message("LobbyBrowser ready.");
