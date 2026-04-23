/// Create_0 — obj_login
/// Uses Supabase Auth REST API directly — no local backend needed.

// Supabase config — same values as server.cpp
#macro SUPABASE_URL_AUTH "https://zqnvimeyzogmtgydrkuz.supabase.co"
#macro SUPABASE_ANON_KEY "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpxbnZpbWV5em9nbXRneWRya3V6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY3MjcwNzEsImV4cCI6MjA5MjMwMzA3MX0.vRLJw3_Ve6Az-0K2PJphwg8cE9juG4y2p7VYMPbR5io"

username_text  = "";
password_text  = "";
active_field   = 0;   // 0 = username, 1 = password
last_char_used = "";
status_text    = "Enter your username and password.";
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
