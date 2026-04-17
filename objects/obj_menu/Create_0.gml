if (!variable_global_exists("auth_token")) global.auth_token = "";
if (!variable_global_exists("username")) global.username = "";
if (!variable_global_exists("user_role")) global.user_role = "";

menu_buttons = [];

array_push(menu_buttons, {
    label: "Play Game",
    target: rm_loadout,
    action: "room",
    desc: "Enter the arena and test powerups",
    primary: true,
    requires_login: false
});

array_push(menu_buttons, {
    label: "Login",
    target: rm_login,
    action: "room",
    desc: "Sign into your account",
    primary: false,
    requires_login: false
});

array_push(menu_buttons, {
    label: "Register",
    target: rm_register,
    action: "room",
    desc: "Create a new account",
    primary: false,
    requires_login: false
});

array_push(menu_buttons, {
    label: "Create Lobby",
    target: rm_create_lobby,
    action: "room",
    desc: "Start a new public or private lobby",
    primary: false,
    requires_login: true
});

array_push(menu_buttons, {
    label: "Browse Lobbies",
    target: rm_browse_lobbies,
    action: "room",
    desc: "View and join available lobbies",
    primary: false,
    requires_login: false
});

array_push(menu_buttons, {
    label: "Leaderboard",
    target: rm_leaderboard,
    action: "room",
    desc: "View player rankings and match stats",
    primary: false,
    requires_login: false
});

array_push(menu_buttons, {
    label: "Logout",
    target: rm_login,
    action: "logout",
    desc: "Clear your session and return to login",
    primary: false,
    requires_login: true
});

button_w = 320;
button_h = 48;
button_gap = 12;

hover_index = -1;
status_text = "Welcome to Project Rewind.";