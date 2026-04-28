/// Create_0 — obj_login
/// Uses Supabase Auth REST API directly — no local backend needed.
/// Supabase config macros are in scr_supabase_config.gml

username_text  = "";
password_text  = "";
active_field   = 0;   // 0 = username, 1 = password
last_char_used = "";
status_text    = "Enter your email and password.";
login_request_id = -1;

button_w    = 140;
button_h    = 40;
hover_login    = false;
hover_register = false;

// Safe globals
if (!variable_global_exists("auth_token")) global.auth_token = "";
if (!variable_global_exists("username"))   global.username   = "";
if (!variable_global_exists("user_role"))  global.user_role  = "";
if (!variable_global_exists("user_id"))    global.user_id    = "";
