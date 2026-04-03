if (keyboard_check_pressed(vk_tab)) {
    active_field = 1 - active_field;
}

// Backspace
if (keyboard_check_pressed(vk_backspace)) {
    if (active_field == 0 && string_length(username_text) > 0) {
        username_text = string_delete(username_text, string_length(username_text), 1);
    }

    if (active_field == 1 && string_length(password_text) > 0) {
        password_text = string_delete(password_text, string_length(password_text), 1);
    }
}

// Safe typing
var c = keyboard_lastchar;

if (c != "" && c != last_char_used) {
    var code = ord(c);

    if (code >= 32 && code <= 126) {
        if (active_field == 0 && string_length(username_text) < 24) {
            username_text += c;
        }

        if (active_field == 1 && string_length(password_text) < 24) {
            password_text += c;
        }
    }

    last_char_used = c;
}

// Reset char lock
if (keyboard_lastchar == "") {
    last_char_used = "";
}

// Submit login
if (keyboard_check_pressed(vk_enter)) {
    if (username_text == "" || password_text == "") {
        status_text = "Username and password are required.";
    } else {
        status_text = "Logging in...";

        var body = json_stringify({
            username: username_text,
            password: password_text
        });

        login_request_id = http_request(
            base_url + "/api/login",
            "POST",
            "Content-Type: application/json\r\n",
            body
        );
    }
}
if (keyboard_check_pressed(vk_escape)) {
    room_goto(rm_login);
}