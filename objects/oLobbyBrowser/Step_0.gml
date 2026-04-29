/// Step_0 — oLobbyBrowser

// ════════════════════════════════════════════════════════════════════════════
//  SERVER POLL — waiting for manager-spawned server to respond
// ════════════════════════════════════════════════════════════════════════════
if (launching) {
    launch_timeout--;
    if (launch_timeout <= 0) {
        launching = false;
        if (game_socket >= 0) { network_destroy(game_socket); game_socket = -1; }
        status_msg     = "Server failed to start. Try again.";
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
//  CREATE PENDING — waiting for manager CREATE_ACK (type 51)
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
//  SCREEN: CREATE LOBBY
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
            send_online_create_request();
        }
    }

    if (keyboard_check_pressed(vk_escape)) {
        current_screen = SCREEN_BROWSE;
        status_msg     = "";
        create_name    = ""; create_pw = ""; create_private = false; create_focus = "name";
        request_lobby_list();
    }

    exit;
}

// ════════════════════════════════════════════════════════════════════════════
//  SCREEN: BROWSE
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
    status_msg = "Name your lobby.  P = private.  ESC = back.";
}

if (keyboard_check_pressed(ord("R")) && !join_pending) {
    request_lobby_list();
    status_msg = "Refreshing...";
}

if (keyboard_check_pressed(vk_escape) && !join_pending) {
    room_goto(rm_menu);
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
