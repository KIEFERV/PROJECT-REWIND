base_url = "http://localhost:8080";

username_text = "";
password_text = "";

active_field = 0; // 0 = username, 1 = password
last_char_used = "";

status_text = "Enter your username and password.";
login_request_id = -1;

// safe globals
if (!variable_global_exists("auth_token")) global.auth_token = "";
if (!variable_global_exists("username")) global.username = "";
if (!variable_global_exists("user_role")) global.user_role = "";

// button layout values
button_w = 140;
button_h = 40;

hover_login = false;
hover_register = false;

// store login 
global.auth_token = "";
global.username = "";
global.user_role = "";