if (keyboard_check_pressed(vk_tab)) {
    active_field += 1;
    if (active_field > 3) active_field = 0;
}

// Backspace
if (keyboard_check_pressed(vk_backspace)) {
    if (active_field == 0 && string_length(email_text) > 0) {
        email_text = string_delete(email_text, string_length(email_text), 1);
    }

    if (active_field == 1 && string_length(username_text) > 0) {
        username_text = string_delete(username_text, string_length(username_text), 1);
    }

    if (active_field == 2 && string_length(password_text) > 0) {
        password_text = string_delete(password_text, string_length(password_text), 1);
    }

    if (active_field == 3 && string_length(confirm_text) > 0) {
        confirm_text = string_delete(confirm_text, string_length(confirm_text), 1);
    }
}

// Safe typing
var c = keyboard_lastchar;

if (c != "" && c != last_char_used) {
    var code = ord(c);

    if (code >= 32 && code <= 126) {
        if (active_field == 0 && string_length(email_text) < 40) {
            email_text += c;
        }

        if (active_field == 1 && string_length(username_text) < 24) {
            username_text += c;
        }

        if (active_field == 2 && string_length(password_text) < 24) {
            password_text += c;
        }

        if (active_field == 3 && string_length(confirm_text) < 24) {
            confirm_text += c;
        }
    }

    last_char_used = c;
}

// Reset char lock
if (keyboard_lastchar == "") {
    last_char_used = "";
}

// Submit register
if (keyboard_check_pressed(vk_enter)) {
    if (email_text == "" || username_text == "" || password_text == "" || confirm_text == "") {
        status_text = "All fields are required.";
    }
    else if (password_text != confirm_text) {
        status_text = "Passwords do not match.";
    }
    else {
        status_text = "Registering...";

        var body = json_stringify({
            email: email_text,
            username: username_text,
            password: password_text
        });

        register_request_id = http_request(
            base_url + "/api/register",
            "POST",
            "Content-Type: application/json\r\n",
            body
        );
    }
}

// Back to login
if (keyboard_check_pressed(vk_escape)) {
    room_goto(rm_login);
}