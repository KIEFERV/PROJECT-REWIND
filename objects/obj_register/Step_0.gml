if (keyboard_check_pressed(vk_tab)) {
    active_field += 1;
    if (active_field > 3) active_field = 0;
}

// Backspace
if (keyboard_check_pressed(vk_backspace)) {
    if (active_field == 0 && string_length(email_text) > 0)
        email_text = string_delete(email_text, string_length(email_text), 1);
    if (active_field == 1 && string_length(username_text) > 0)
        username_text = string_delete(username_text, string_length(username_text), 1);
    if (active_field == 2 && string_length(password_text) > 0)
        password_text = string_delete(password_text, string_length(password_text), 1);
    if (active_field == 3 && string_length(confirm_text) > 0)
        confirm_text = string_delete(confirm_text, string_length(confirm_text), 1);
}

// Safe typing
var c = keyboard_lastchar;

if (c != "" && c != last_char_used) {
    var code = ord(c);

    if (code >= 32 && code <= 126) {
        if (active_field == 0 && string_length(email_text) < 40)
            email_text += c;
        if (active_field == 1 && string_length(username_text) < 24)
            username_text += c;
        if (active_field == 2 && string_length(password_text) < 24)
            password_text += c;
        if (active_field == 3 && string_length(confirm_text) < 24)
            confirm_text += c;
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

        // Supabase signUp — stores username and role in user_metadata
        var body = json_stringify({
            email:    email_text,
            password: password_text,
            data: {
                username: username_text,
                role:     "player"
            },
            options: {
                email_redirect_to: ""
            }
        });

        var headers = ds_map_create();
        ds_map_add(headers, "Content-Type", "application/json");
        ds_map_add(headers, "apikey",       SUPABASE_ANON_KEY);
        register_request_id = http_request(
            SUPABASE_URL_AUTH + "/auth/v1/signup",
            "POST",
            headers,
            body
        );
        ds_map_destroy(headers);
    }
}

// Back to login
if (keyboard_check_pressed(vk_escape)) {
    room_goto(rm_login);
}