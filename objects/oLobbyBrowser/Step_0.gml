/// Step_0 — oLobbyBrowser

// ════════════════════════════════════════════════════════════════════════════
//  SERVER LAUNCH POLLING
//  After execute_shell_simple() we send a type-10 join packet to 127.0.0.1:7777
//  every LAUNCH_POLL_TICKS steps. When server.exe is ready it replies with
//  type 2 (pid assignment), which the Async event catches and transitions on.
// ════════════════════════════════════════════════════════════════════════════
if (launching) {
    // Safety timeout — give up after LAUNCH_TIMEOUT ticks
    launch_timeout--;
    if (launch_timeout <= 0) {
        launching = false;
        if (game_socket >= 0) { network_destroy(game_socket); game_socket = -1; }
        status_msg = "Server failed to start. Check server.exe path in SERVER_EXE macro.";
        show_debug_message("Server launch timed out. SERVER_EXE = " + SERVER_EXE);
        current_screen = SCREEN_CREATE;
        exit;
    }

    // Send a ping every LAUNCH_POLL_TICKS
    launch_poll_timer--;
    if (launch_poll_timer <= 0) {
        launch_poll_timer = LAUNCH_POLL_TICKS;
        ping_local_server();
        show_debug_message("Pinging 127.0.0.1:7777... (" + string(launch_timeout) + " ticks remaining)");
    }

    exit; // block all other input while waiting
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
            launch_server_and_host();
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
//  SCREEN: BROWSE — password overlay
// ════════════════════════════════════════════════════════════════════════════
if (pw_mode) {
    pw_input = text_input_step(pw_input);

    if (keyboard_check_pressed(vk_escape)) {
        pw_mode        = false;
        pw_input       = "";
        pw_pending_idx = -1;
        status_msg     = "Join cancelled.";
    }

    if (keyboard_check_pressed(vk_return)) {
        var _entry = ds_list_find_value(lobby_list, pw_pending_idx);
        db_send_join(_entry[? "id"], hash_password(pw_input));
        pw_mode      = false;
        pw_input     = "";
        join_pending = true;
        join_timeout = JOIN_TIMEOUT_TICKS;
        status_msg   = "Joining...";
    }

    exit;
}

// ════════════════════════════════════════════════════════════════════════════
//  SCREEN: BROWSE — normal navigation
// ════════════════════════════════════════════════════════════════════════════
var _count = ds_list_size(lobby_list);

refresh_timer++;
if (refresh_timer >= REFRESH_TICKS && !join_pending) {
    refresh_timer = 0;
    db_request_list();
}

if (join_pending) {
    join_timeout--;
    if (join_timeout <= 0) {
        join_pending = false;
        status_msg   = "No response from server. Try again.";
    }
}

if (keyboard_check_pressed(vk_up))
    selected_index = max(0, selected_index - 1);
if (keyboard_check_pressed(vk_down))
    selected_index = min(max(0, _count - 1), selected_index + 1);

if (keyboard_check_pressed(ord("C")) && !join_pending) {
    current_screen = SCREEN_CREATE;
    create_name    = "";
    create_pw      = "";
    create_private = false;
    create_focus   = "name";
    status_msg     = "Name your lobby.  P = toggle private.  ESC = back.";
}

if (keyboard_check_pressed(ord("R")) && !join_pending) {
    db_request_list();
    status_msg = "Refreshing...";
}

if (keyboard_check_pressed(vk_return) && _count > 0 && !join_pending) {
    var _entry  = ds_list_find_value(lobby_list, selected_index);
    var _has_pw = _entry[? "has_password"];
    if (_has_pw) {
        pw_mode        = true;
        pw_input       = "";
        pw_pending_idx = selected_index;
        status_msg     = "Enter password:";
    } else {
        db_send_join(_entry[? "id"], "");
        join_pending = true;
        join_timeout = JOIN_TIMEOUT_TICKS;
        status_msg   = "Joining...";
    }
}
