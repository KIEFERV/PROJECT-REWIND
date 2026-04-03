// Go to register screen
if (keyboard_check_pressed(ord("R"))) {
    room_goto(rm_register);
}

// Go to create lobby screen
if (keyboard_check_pressed(ord("C"))) {
    room_goto(rm_create_lobby);
}

// Go to browse lobbies
if (keyboard_check_pressed(ord("B"))) {
    room_goto(rm_browse_lobbies);
}

// Log out → return to login
if (keyboard_check_pressed(ord("L"))) {
    global.auth_token = "";
    room_goto(rm_login);
}