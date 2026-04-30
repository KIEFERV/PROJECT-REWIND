/// Create_0 — obj_menu

if (!variable_global_exists("auth_token")) global.auth_token = "";
if (!variable_global_exists("username"))   global.username   = "";
if (!variable_global_exists("user_role"))  global.user_role  = "";
if (!variable_global_exists("user_id"))    global.user_id    = "";

menu_buttons = [];

array_push(menu_buttons, {
    label:          "Practice Room",
    target:         rm_loadout,
    action:         "room",
    desc:           "Jump into a solo practice match",
    primary:        true,
    requires_login: false
});

array_push(menu_buttons, {
    label:          "Play Online",
    target:         rm_menu,   // existing lobby browser room
    action:         "room",
    desc:           "Browse and join online or LAN lobbies",
    primary:        false,
    requires_login: false
});

array_push(menu_buttons, {
    label:          "Leaderboard",
    target:         rm_leaderboard,
    action:         "room",
    desc:           "View player rankings and match stats",
    primary:        false,
    requires_login: false
});

array_push(menu_buttons, {
    label:               "Login",
    target:              rm_login,
    action:              "room",
    desc:                "Sign into your account",
    primary:             false,
    requires_login:      false,
    hide_when_logged_in: true
});

array_push(menu_buttons, {
    label:               "Register",
    target:              rm_register,
    action:              "room",
    desc:                "Create a new account",
    primary:             false,
    requires_login:      false,
    hide_when_logged_in: true
});

array_push(menu_buttons, {
    label:                "Logout",
    target:               rm_login,
    action:               "logout",
    desc:                 "Clear your session and return to login",
    primary:              false,
    requires_login:       true,
    hide_when_logged_in:  false
});

button_w   = 320;
button_h   = 48;
button_gap = 12;

hover_index = -1;
status_text = "Welcome to Project Rewind.";
