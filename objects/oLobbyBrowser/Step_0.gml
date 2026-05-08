/// Step_0 — oLobbyBrowser

var _gw  = display_get_gui_width();
var _gh  = display_get_gui_height();
var _cx  = _gw / 2;
var _mx  = device_mouse_x_to_gui(0);
var _my  = device_mouse_y_to_gui(0);
var _clk = mouse_check_button_pressed(mb_left);

// ════════════════════════════════════════════════════════════════════════════
//  SERVER POLL
// ════════════════════════════════════════════════════════════════════════════
if (launching) {
    launch_timeout--;
    if (launch_timeout <= 0) {
        launching      = false;
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
//  CREATE PENDING
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

    var _pw  = 500; var _ph = 340;
    var _px  = _cx - _pw / 2;
    var _py  = _gh / 2 - _ph / 2;
    var _lx  = _px + 30;
    var _fx  = _px + 150;
    var _fw  = _pw - 180;
    var _fh  = 30;
    var _fy  = _py + 90;
    var _gap = 54;

    // Name field click to focus
    if (_clk && point_in_rectangle(_mx, _my, _fx, _fy, _fx + _fw, _fy + _fh)) {
        create_focus = "name";
    }
    _fy += _gap;

    // Visibility buttons
    var _bw    = 130;
    var _pub_x  = _fx;
    var _priv_x = _fx + _bw + 10;
    if (_clk && point_in_rectangle(_mx, _my, _pub_x, _fy, _pub_x + _bw, _fy + _fh)) {
        create_private = false; create_pw = ""; create_focus = "name";
    }
    if (_clk && point_in_rectangle(_mx, _my, _priv_x, _fy, _priv_x + _bw, _fy + _fh)) {
        create_private = true; create_focus = "password";
    }
    _fy += _gap;

    // Password field click
    if (create_private) {
        if (_clk && point_in_rectangle(_mx, _my, _fx, _fy, _fx + _fw, _fy + _fh)) {
            create_focus = "password";
        }
        _fy += _gap;
    }

    // Keyboard input for focused field
    if (create_focus == "name" && string_length(create_name) < 24)
        create_name = text_input_step(create_name);
    else if (create_focus == "password" && create_private && string_length(create_pw) < 32)
        create_pw = text_input_step(create_pw);

    // Create button click
    var _cbw = 180; var _cbh = 36;
    var _cbx = _cx - _cbw / 2; var _cby = _py + _ph - 55;
    if ((_clk && point_in_rectangle(_mx, _my, _cbx, _cby, _cbx + _cbw, _cby + _cbh))
        || keyboard_check_pressed(vk_enter)) {
        var _name_ok = (string_length(string_trim(create_name)) > 0);
        var _pw_ok   = (!create_private || string_length(create_pw) > 0);
        if (!_name_ok) {
            status_msg = "Please enter a lobby name.";
        } else if (!_pw_ok) {
            status_msg = "Please enter a password.";
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

// Password overlay input
if (pw_mode) {
    pw_input = text_input_step(pw_input);

    // ESC or Cancel button
    var _ccy = _gh / 2 - 75 + 150 - 46;
    var _ccx = _cx + 10; var _cfw = 70; var _cfh = 28;
    if (keyboard_check_pressed(vk_escape)
        || (_clk && point_in_rectangle(_mx, _my, _ccx, _ccy, _ccx + _cfw, _ccy + _cfh))) {
        pw_mode = false; pw_input = ""; pw_pending_idx = -1;
        status_msg = "Join cancelled.";
    }

    // ENTER or Join button
    var _cfx = _cx - 80; var _cfy = _ccy;
    if (keyboard_check_pressed(vk_return)
        || (_clk && point_in_rectangle(_mx, _my, _cfx, _cfy, _cfx + _cfw, _cfy + _cfh))) {
        var _entry = ds_list_find_value(lobby_list, pw_pending_idx);
        send_join_request(_entry[? "id"], hash_password(pw_input));
        pw_mode = false; pw_input = "";
        join_pending = true; join_timeout = JOIN_TIMEOUT_TICKS;
        status_msg = "Joining...";
    }
    exit;
}

// Join timeout
if (join_pending) {
    join_timeout--;
    if (join_timeout <= 0) { join_pending = false; status_msg = "No response. Try again."; }
}

// Auto-refresh
refresh_timer++;
if (refresh_timer >= REFRESH_TICKS && !join_pending) {
    refresh_timer = 0;
    request_lobby_list();
}

// Bottom button clicks and keyboard
var _btn_y  = _gh - 56; var _btn_h = 32; var _btn_bw = 110;
var _btn_c  = 120; var _btn_r = 260; var _btn_bk = _gw - 140;

// Create
if ((_clk && point_in_rectangle(_mx, _my, _btn_c, _btn_y, _btn_c + _btn_bw, _btn_y + _btn_h))
    || keyboard_check_pressed(ord("C"))) {
    current_screen = SCREEN_CREATE;
    create_name    = ""; create_pw = ""; create_private = false; create_focus = "name";
    status_msg     = "Name your lobby.";
}

// Refresh
if ((_clk && point_in_rectangle(_mx, _my, _btn_r, _btn_y, _btn_r + _btn_bw, _btn_y + _btn_h))
    || keyboard_check_pressed(ord("R"))) {
    request_lobby_list();
    status_msg = "Refreshing...";
}

// Back
if ((_clk && point_in_rectangle(_mx, _my, _btn_bk, _btn_y, _btn_bk + _btn_bw, _btn_y + _btn_h))
    || keyboard_check_pressed(vk_escape)) {
    room_goto(rm_menu);
}

// Lobby row clicks — click row or JOIN button
var _count   = ds_list_size(lobby_list);
var _row_top = 90; var _row_h = 32;

for (var _i = 0; _i < _count; _i++) {
    var _ry  = _row_top + 28 + _i * _row_h;
    var _row_hov = point_in_rectangle(_mx, _my, 48, _ry - 3, _gw - 48, _ry + _row_h - 4);

    // Hover selects
    if (_row_hov) selected_index = _i;

    // Click to join
    if (_clk && _row_hov && !join_pending) {
        var _entry  = ds_list_find_value(lobby_list, _i);
        var _has_pw = _entry[? "has_password"];
        if (_has_pw) {
            pw_mode = true; pw_input = ""; pw_pending_idx = _i;
            status_msg = "Enter password:";
        } else {
            send_join_request(_entry[? "id"], "");
            join_pending = true; join_timeout = JOIN_TIMEOUT_TICKS;
            status_msg = "Joining...";
        }
    }
}

// Keyboard navigation still works
if (keyboard_check_pressed(vk_up))
    selected_index = max(0, selected_index - 1);
if (keyboard_check_pressed(vk_down))
    selected_index = min(max(0, _count - 1), selected_index + 1);
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
