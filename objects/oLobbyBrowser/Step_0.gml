/// Step_0 — oLobbyBrowser

// ════════════════════════════════════════════════════════════════════════════
//  SERVER LAUNCH POLLING
// ════════════════════════════════════════════════════════════════════════════
if (launching) {
    launch_timeout--;
    if (launch_timeout <= 0) {
        launching = false;
        if (game_socket >= 0) { network_destroy(game_socket); game_socket = -1; }
        status_msg = "Server failed to start. Check SERVER_EXE path.";
        current_screen = SCREEN_CREATE;
        exit;
    }
    launch_poll_timer--;
    if (launch_poll_timer <= 0) {
        launch_poll_timer = LAUNCH_POLL_TICKS;
        ping_game_server();
    }
    exit;
}

// ════════════════════════════════════════════════════════════════════════════
//  ONLINE CREATE PENDING — waiting for manager CREATE_ACK (type 51)
// ════════════════════════════════════════════════════════════════════════════
if (create_pending) {
    create_timeout--;
    if (create_timeout <= 0) {
        create_pending = false;
        status_msg     = "No response from server. Try again.";
        current_screen = SCREEN_CREATE;
    }
    exit;
}

// ════════════════════════════════════════════════════════════════════════════
//  SCREEN: MODE SELECT  (Online vs LAN)
// ════════════════════════════════════════════════════════════════════════════
if (current_screen == SCREEN_MODE) {

    // O — Online
    if (keyboard_check_pressed(ord("O"))) {
        is_lan_mode      = false;
        active_server_ip = VPS_IP;
        current_screen   = SCREEN_BROWSE;
        status_msg       = "Fetching lobbies...";
        request_lobby_list();
    }

    // L — LAN
    if (keyboard_check_pressed(ord("L"))) {
        is_lan_mode    = true;
        current_screen = SCREEN_LAN;
        lan_join_mode  = true;
        lan_ip_input   = "";
        status_msg     = "";
    }

    exit;
}

// ════════════════════════════════════════════════════════════════════════════
//  SCREEN: LAN
// ════════════════════════════════════════════════════════════════════════════
if (current_screen == SCREEN_LAN) {

    // TAB switches between Join and Host tabs
    if (keyboard_check_pressed(vk_tab)) {
        lan_join_mode = !lan_join_mode;
        lan_ip_input  = "";
        status_msg    = "";

        // Launch server immediately when switching to HOST tab
        if (!lan_join_mode && !launching) {
            launch_server_and_host();
        }
    }

    if (lan_join_mode) {
        // ── JOIN TAB — type host IP and press ENTER ───────────────────────
        // Accept digits and dots only
        for (var _k = ord("0"); _k <= ord("9"); _k++) {
            if (keyboard_check_pressed(_k) && string_length(lan_ip_input) < 15)
                lan_ip_input += chr(_k);
        }
        if (keyboard_check_pressed(vk_numpad0)) lan_ip_input += "0";
        if (keyboard_check_pressed(vk_numpad1)) lan_ip_input += "1";
        if (keyboard_check_pressed(vk_numpad2)) lan_ip_input += "2";
        if (keyboard_check_pressed(vk_numpad3)) lan_ip_input += "3";
        if (keyboard_check_pressed(vk_numpad4)) lan_ip_input += "4";
        if (keyboard_check_pressed(vk_numpad5)) lan_ip_input += "5";
        if (keyboard_check_pressed(vk_numpad6)) lan_ip_input += "6";
        if (keyboard_check_pressed(vk_numpad7)) lan_ip_input += "7";
        if (keyboard_check_pressed(vk_numpad8)) lan_ip_input += "8";
        if (keyboard_check_pressed(vk_numpad9)) lan_ip_input += "9";
        if (keyboard_check_pressed(ord(".")) && string_length(lan_ip_input) < 15)
            lan_ip_input += ".";
        if (keyboard_check_pressed(vk_backspace) && string_length(lan_ip_input) > 0)
            lan_ip_input = string_copy(lan_ip_input, 1, string_length(lan_ip_input) - 1);

        // ENTER — connect to typed IP
        if (keyboard_check_pressed(vk_return)) {
            if (string_length(lan_ip_input) >= 7) {  // minimum valid IP length
                global.ip_address        = lan_ip_input;
                global.port              = GAME_PORT_NUM;
                global.is_creating_lobby = false;
                if (lobby_socket >= 0) { network_destroy(lobby_socket); lobby_socket = -1; }
                room_goto(rLobby);
            } else {
                status_msg = "Enter a valid IP address.";
            }
        }

    } else {
        // ── HOST TAB — server is running, show local IP ───────────────────
        // Nothing to do here — draw event shows the IP
    }

    // ESC — back to mode select
    if (keyboard_check_pressed(vk_escape)) {
        current_screen = SCREEN_MODE;
        lan_ip_input   = "";
        status_msg     = "";
    }

    exit;
}

// ════════════════════════════════════════════════════════════════════════════
//  SCREEN: CREATE LOBBY (online)
// ════════════════════════════════════════════════════════════════════════════
if (current_screen == SCREEN_CREATE) {

    if (keyboard_check_pressed(vk_tab)) {
        if (create_private)
            create_focus = (create_focus == "name") ? "password" : "name";
    }

    if (create_focus == "name") {
        if (string_length(create_name) < 24)
            create_name = text_input_step(create_name);
    } else {
        if (string_length(create_pw) < 32)
            create_pw = text_input_step(create_pw);
    }

    if (keyboard_check_pressed(ord("P"))) {
        create_private = !create_private;
        if (!create_private) { create_pw = ""; create_focus = "name"; }
    }

    if (keyboard_check_pressed(vk_return)) {
        var _name_ok = (string_length(string_trim(create_name)) > 0);
        var _pw_ok   = (!create_private || string_length(create_pw) > 0);
        if (!_name_ok) {
            status_msg = "Please enter a lobby name.";
        } else if (!_pw_ok) {
            status_msg = "Please enter a password for the private lobby.";
        } else {
            if (is_lan_mode) {
                launch_server_and_host();   // LAN — local server.exe
            } else {
                send_online_create_request(); // Online — ask Droplet manager
            }
        }
    }

    if (keyboard_check_pressed(vk_escape)) {
        current_screen = SCREEN_BROWSE;
        status_msg     = "Select a lobby or press C to create one.";
        create_name    = "";
        create_pw      = "";
        create_private = false;
        create_focus   = "name";
    }

    exit;
}

// ════════════════════════════════════════════════════════════════════════════
//  SCREEN: BROWSE (online)
// ════════════════════════════════════════════════════════════════════════════

// Password overlay
if (pw_mode) {
    pw_input = text_input_step(pw_input);
    if (keyboard_check_pressed(vk_escape)) {
        pw_mode = false; pw_input = ""; pw_pending_idx = -1;
        status_msg = "Join cancelled.";
    }
    if (keyboard_check_pressed(vk_return)) {
        var _entry = ds_list_find_value(lobby_list, pw_pending_idx);
        send_join_request(_entry[? "id"], hash_password(pw_input));
        pw_mode = false; pw_input = "";
        join_pending = true; join_timeout = JOIN_TIMEOUT_TICKS;
        status_msg = "Joining...";
    }
    exit;
}

var _count = ds_list_size(lobby_list);

refresh_timer++;
if (refresh_timer >= REFRESH_TICKS && !join_pending) {
    refresh_timer = 0;
    request_lobby_list();
}

if (join_pending) {
    join_timeout--;
    if (join_timeout <= 0) { join_pending = false; status_msg = "No response. Try again."; }
}

if (keyboard_check_pressed(vk_up))
    selected_index = max(0, selected_index - 1);
if (keyboard_check_pressed(vk_down))
    selected_index = min(max(0, _count - 1), selected_index + 1);

if (keyboard_check_pressed(ord("C")) && !join_pending) {
    current_screen = SCREEN_CREATE;
    create_name = ""; create_pw = ""; create_private = false; create_focus = "name";
    status_msg = "Name your lobby.  P = toggle private.  ESC = back.";
}

if (keyboard_check_pressed(ord("R")) && !join_pending) {
    request_lobby_list(); status_msg = "Refreshing...";
}

// ESC — back to mode select
if (keyboard_check_pressed(vk_escape) && !join_pending) {
    current_screen = SCREEN_MODE;
    cleanup_lobby_list();
    status_msg = "";
}

if (keyboard_check_pressed(vk_return) && _count > 0 && !join_pending) {
    var _entry  = ds_list_find_value(lobby_list, selected_index);
    var _has_pw = _entry[? "has_password"];
    if (_has_pw) {
        pw_mode = true; pw_input = ""; pw_pending_idx = selected_index;
        status_msg = "Enter password:";
    } else {
        send_join_request(_entry[? "id"], "");
        join_pending = true; join_timeout = JOIN_TIMEOUT_TICKS;
        status_msg = "Joining...";
    }
}
