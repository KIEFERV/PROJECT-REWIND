/// Create_0 — oLobbyBrowser
///
/// Two screens in one object:
///   SCREEN_BROWSE  — shows live lobby list, join with ENTER
///   SCREEN_CREATE  — form to name a lobby, set public/private, enter password
///
/// When the player creates a lobby:
///   1. server.exe is launched via execute_shell_simple().
///   2. The client polls 127.0.0.1:7777 with a type-10 join packet each step
///      until the server responds with a type-2 pid assignment, then transitions.
///      This is more reliable than a fixed timer and works regardless of how
///      long server.exe takes to start.
///
/// ─── SETUP ────────────────────────────────────────────────────────────────
///   • Place one instance of oLobbyBrowser in a room called rServerBrowser.
///   • Set rServerBrowser as the FIRST room in your game.
///   • Edit the four config constants below.
///   • SERVER_EXE must be the full absolute path to server.exe.
///     During development this is wherever you compiled it.
///     In a release build, use:  working_directory + "server.exe"

// ═══════════════════════════════════════════════════════════════════════════
//  CONFIGURATION — edit these before running
// ═══════════════════════════════════════════════════════════════════════════

// IP of the machine running lobby_db_server
#macro DB_IP        "127.0.0.1"

// Port lobby_db_server listens on
#macro DB_PORT_NUM  8888

// Full path to server.exe
// • During IDE development: use the absolute path where you compiled it, e.g.
//     "C:\\Users\\Kiefer\\GameMakerProjects\\PROJECT-REWIND\\server\\server.exe"
// • In a compiled release build: working_directory + "server.exe"
#macro SERVER_EXE   "C:\\Users\\Kiefer\\GameMakerProjects\\PROJECT-REWIND\\server\\server.exe"

// This machine's LAN/public IP shown to other players in the lobby list
#macro MY_PUBLIC_IP "127.0.0.1"

// ═══════════════════════════════════════════════════════════════════════════
//  SCREEN IDs
// ═══════════════════════════════════════════════════════════════════════════
#macro SCREEN_BROWSE  0
#macro SCREEN_CREATE  1

// ─── Sockets ──────────────────────────────────────────────────────────────
// db_socket  — talks to lobby_db_server (port 8888)
// game_socket — talks to the local server.exe (port 7777) while waiting for it
db_socket      = network_create_socket(network_socket_udp);
game_socket    = -1;    // created only during server-launch polling
current_screen = SCREEN_BROWSE;

// Reset connection globals cleanly
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

// ─── Join flow (joining someone else's lobby) ─────────────────────────────
join_pending       = false;
join_timeout       = 0;
JOIN_TIMEOUT_TICKS = 5 * game_get_speed(gamespeed_fps);

// ─── Password-prompt state (for joining a private lobby) ──────────────────
pw_mode        = false;
pw_input       = "";
pw_pending_idx = -1;

// ─── Create-lobby form state ───────────────────────────────────────────────
create_focus   = "name";     // which field has keyboard focus: "name" | "password"
create_name    = "";
create_private = false;
create_pw      = "";

// ─── Server-launch / poll state ───────────────────────────────────────────
// After execute_shell_simple() we ping 127.0.0.1:7777 every step until we
// get a type-2 pid response, then transition to rLobby.
launching         = false;   // true while waiting for server.exe to respond
launch_poll_timer = 0;       // ticks until we send the next ping
LAUNCH_POLL_TICKS = game_get_speed(gamespeed_fps) / 4;  // ping 4 times/sec
launch_timeout    = 0;       // safety cut-off
LAUNCH_TIMEOUT    = 10 * game_get_speed(gamespeed_fps); // give up after 10 s

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

// ─── Send list request (type 25) to DB server ─────────────────────────────
function db_request_list() {
    var _b = buffer_create(1, buffer_fixed, 1);
    buffer_write(_b, buffer_u8, 25);
    network_send_udp_raw(db_socket, DB_IP, DB_PORT_NUM, _b, 1);
    buffer_delete(_b);
}

// ─── Send join request (type 30) to DB server ─────────────────────────────
function db_send_join(_lobby_id, _pw_hash) {
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
    network_send_udp_raw(db_socket, DB_IP, DB_PORT_NUM, _b, buffer_tell(_b));
    buffer_delete(_b);
}

// ─── Ping the local game server to check it is alive ──────────────────────
// Sends type-255 (PING) — the server echoes type-255 back without
// registering a player slot or consuming a pid.
// This means pid=1 is still available for oLobby's proper type-10 join.
function ping_local_server() {
    if (game_socket < 0) exit;
    var _b = buffer_create(1, buffer_fixed, 1);
    buffer_write(_b, buffer_u8, 255);   // type 255 = ping (no registration)
    network_send_udp_raw(game_socket, "127.0.0.1", 7777, _b, 1);
    buffer_delete(_b);
}

// ─── Launch server.exe and begin polling it ───────────────────────────────
function launch_server_and_host() {
    var _pw_arg    = "";
    if (create_private && create_pw != "")
        _pw_arg = hash_password(create_pw);

    var _safe_name = string_replace_all(create_name, "\"", "");
    if (_safe_name == "") _safe_name = "My Lobby";

    // server.exe expects: <lobby_name> <db_ip> <public_ip> [password_hash]
    var _args = "\"" + _safe_name + "\" " + DB_IP + " " + MY_PUBLIC_IP;
    if (_pw_arg != "") _args += " " + _pw_arg;

    // Determine the working directory for server.exe
    // (the folder that contains server.exe)
    var _server_dir = filename_dir(SERVER_EXE) + "\\";

    execute_shell_simple(SERVER_EXE, _args, "open", 1, _server_dir);
    show_debug_message("Launched: " + SERVER_EXE + " " + _args);

    // Mark this client as the lobby creator so oLobby shows host UI immediately
    global.is_creating_lobby = true;
    global.ip_address        = "127.0.0.1";
    global.port              = 7777;

    // Open a temporary UDP socket just to detect when server.exe is ready.
    // This socket is destroyed once we get a response — oLobby creates its own.
    if (game_socket >= 0) network_destroy(game_socket);
    game_socket = network_create_socket(network_socket_udp);

    launching         = true;
    launch_poll_timer = 0;
    launch_timeout    = LAUNCH_TIMEOUT;
    status_msg        = "Starting server...";
}

// ─── Free ds_maps inside lobby_list ───────────────────────────────────────
function cleanup_lobby_list() {
    if (!ds_exists(lobby_list, ds_type_list)) exit;
    for (var _i = 0; _i < ds_list_size(lobby_list); _i++) {
        var _m = ds_list_find_value(lobby_list, _i);
        if (ds_exists(_m, ds_type_map)) ds_map_destroy(_m);
    }
    ds_list_clear(lobby_list);
}

// ─── Shared text-input helper ──────────────────────────────────────────────
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

// ─── Initial list fetch ────────────────────────────────────────────────────
db_request_list();
show_debug_message("LobbyBrowser ready. DB=" + DB_IP + ":" + string(DB_PORT_NUM));
