if (!variable_global_exists("auth_token")) global.auth_token = "";
if (!variable_global_exists("username")) global.username = "";
if (!variable_global_exists("user_role")) global.user_role = "";

menu_buttons = [];

array_push(menu_buttons, { label: "Login",          target: rm_login,          action: "room",   desc: "Sign into your account" });
array_push(menu_buttons, { label: "Register",       target: rm_register,       action: "room",   desc: "Create a new account" });
array_push(menu_buttons, { label: "Create Lobby",   target: rm_create_lobby,   action: "room",   desc: "Start a new public or private lobby" });
array_push(menu_buttons, { label: "Browse Lobbies", target: rm_browse_lobbies, action: "room",   desc: "View and join available lobbies" });
array_push(menu_buttons, { label: "Logout",         target: rm_login,          action: "logout", desc: "Clear your session and return to login" });

button_w = 300;
button_h = 52;
button_gap = 16;

hover_index = -1;
status_text = "Welcome to Project Rewind.";