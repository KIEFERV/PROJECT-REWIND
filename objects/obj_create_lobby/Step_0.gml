if (keyboard_check_pressed(vk_tab)) {
    active_field += 1;
    if (active_field > 2) active_field = 0;
}

// Toggle private/public
if (keyboard_check_pressed(ord("P"))) {
    is_private = !is_private;
}

// Change participant count
if (active_field == 2) {
    if (keyboard_check_pressed(vk_left)) {
        max_participants -= 1;
        if (max_participants < 2) max_participants = 2;
    }

    if (keyboard_check_pressed(vk_right)) {
        max_participants += 1;
        if (max_participants > 4) max_participants = 4;
    }
}

// Backspace
if (keyboard_check_pressed(vk_backspace)) {
    if (active_field == 0 && string_length(name_text) > 0) {
        name_text = string_delete(name_text, string_length(name_text), 1);
    }

    if (active_field == 1 && string_length(description_text) > 0) {
        description_text = string_delete(description_text, string_length(description_text), 1);
    }
}

// Safe typing
var c = keyboard_lastchar;

if (c != "" && c != last_char_used) {
    var code = ord(c);

    if (code >= 32 && code <= 126) {
        if (active_field == 0 && string_length(name_text) < 32) {
            name_text += c;
        }

        if (active_field == 1 && string_length(description_text) < 80) {
            description_text += c;
        }
    }

    last_char_used = c;
}

// Reset char lock
if (keyboard_lastchar == "") {
    last_char_used = "";
}

// Submit create lobby
if (keyboard_check_pressed(vk_enter)) {
    if (global.auth_token == "") {
        status_text = "You must login first.";
    }
    else if (name_text == "" || description_text == "") {
        status_text = "Name and description are required.";
    }
    else {
        status_text = "Creating lobby...";

        var body = json_stringify({
            name: name_text,
            description: description_text,
            is_private: is_private,
            max_participants: max_participants,
            token: global.auth_token
        });

        create_lobby_request_id = http_request(
            base_url + "/api/lobbies",
            "POST",
            "Content-Type: application/json\r\n",
            body
        );
    }
}

// Back to menu
if (keyboard_check_pressed(vk_escape)) {
    room_goto(rm_menu);
}
