/// Step_0 — oLobbyBrowser

var _count = ds_list_size(lobby_list);

// ════════════════════════════════════════════════════════════════════════════
//  PASSWORD INPUT MODE
// ════════════════════════════════════════════════════════════════════════════
if (pw_mode) {

    // Collect typed characters (printable ASCII 32-126)
    for (var _k = 32; _k <= 126; _k++) {
        if (keyboard_check_pressed(_k)) {
            // Respect shift for uppercase / shifted symbols
            var _ch = chr(_k);
            if (!keyboard_check(vk_shift)) _ch = string_lower(_ch);
            pw_input += _ch;
        }
    }

    // Backspace
    if (keyboard_check_pressed(vk_backspace) && string_length(pw_input) > 0) {
        pw_input = string_copy(pw_input, 1, string_length(pw_input) - 1);
    }

    // Escape = cancel
    if (keyboard_check_pressed(vk_escape)) {
        pw_mode        = false;
        pw_input       = "";
        pw_pending_idx = -1;
        status_msg     = "Join cancelled.";
    }

    // Enter = submit password
    if (keyboard_check_pressed(vk_return)) {
        var _entry   = ds_list_find_value(lobby_list, pw_pending_idx);
        var _lid     = _entry[? "id"];
        var _hash    = hash_password(pw_input);
        db_send_join(_lid, _hash);
        pw_mode       = false;
        pw_input      = "";
        join_pending  = true;
        join_timeout  = JOIN_TIMEOUT_TICKS;
        status_msg    = "Joining...";
    }

    exit;  // block all other input while password prompt is open
}

// ════════════════════════════════════════════════════════════════════════════
//  NORMAL NAVIGATION
// ════════════════════════════════════════════════════════════════════════════

// Auto-refresh
refresh_timer++;
if (refresh_timer >= REFRESH_TICKS && !join_pending) {
    refresh_timer = 0;
    db_request_list();
}

// Join timeout watchdog
if (join_pending) {
    join_timeout--;
    if (join_timeout <= 0) {
        join_pending = false;
        status_msg   = "No response from DB server. Try again.";
    }
}

// Arrow navigation
if (keyboard_check_pressed(vk_up))
    selected_index = max(0, selected_index - 1);
if (keyboard_check_pressed(vk_down))
    selected_index = min(max(0, _count - 1), selected_index + 1);

// R = manual refresh
if (keyboard_check_pressed(ord("R")) && !join_pending) {
    db_request_list();
    status_msg = "Refreshing...";
}

// ENTER = try to join selected lobby
if (keyboard_check_pressed(vk_return) && _count > 0 && !join_pending) {
    var _entry  = ds_list_find_value(lobby_list, selected_index);
    var _has_pw = _entry[? "has_password"];

    if (_has_pw) {
        // Open password prompt
        pw_mode        = true;
        pw_input       = "";
        pw_pending_idx = selected_index;
        status_msg     = "Enter password:";
    } else {
        // No password — send join request directly
        db_send_join(_entry[? "id"], "");
        join_pending = true;
        join_timeout = JOIN_TIMEOUT_TICKS;
        status_msg   = "Joining...";
    }
}
