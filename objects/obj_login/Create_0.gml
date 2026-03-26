base_url = "http://localhost:8080";

username_text = "";
password_text = "";

active_field = 0; // 0 = username, 1 = password
status_text = "Enter your username and password.";

login_request_id = -1;
last_char_used = "";

// store login 
global.auth_token = "";
global.username = "";
global.user_role = "";