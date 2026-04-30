/// Other_62 (Async HTTP) — obj_register
/// Handles Supabase signUp response.
/// When email confirmation is OFF, Supabase returns an access_token immediately.
/// When email confirmation is ON, it returns just a user object with no token.

if (!ds_map_exists(async_load, "id")) exit;
if (async_load[? "id"] != register_request_id) exit;

var http_status = async_load[? "status"];
var result_text = async_load[? "result"];
if (is_undefined(result_text)) result_text = "";

if (result_text == "") {
    status_text = "No response from server.";
    exit;
}

var data = json_parse(result_text);

// Case 1: Supabase returned access_token (email confirmation OFF — auto logged in)
if (is_struct(data) && variable_struct_exists(data, "access_token")) {
    global.auth_token = data.access_token;

    if (variable_struct_exists(data, "user")) {
        var u = data.user;
        global.user_id = variable_struct_exists(u, "id") ? u.id : "";
        if (variable_struct_exists(u, "user_metadata")) {
            var meta = u.user_metadata;
            global.username  = variable_struct_exists(meta, "username") ? meta.username : "";
            global.user_role = variable_struct_exists(meta, "role")     ? meta.role     : "player";
        }
        if (global.username == "" && variable_struct_exists(u, "email"))
            global.username = u.email;
    }

    status_text = "Account created! Welcome, " + global.username + ".";
    show_debug_message("Registered and logged in: " + global.username);
    room_goto(rm_menu);  // go straight to menu — already logged in

// Case 2: Supabase returned user object only (email confirmation ON)
} else if (is_struct(data) && variable_struct_exists(data, "id")) {
    status_text = "Account created! You can now log in.";
    show_debug_message("Registered: " + email_text);
    room_goto(rm_login);

// Case 3: Error
} else {
    var err = "";
    if (is_struct(data)) {
        if (variable_struct_exists(data, "msg"))               err = data.msg;
        else if (variable_struct_exists(data, "message"))      err = data.message;
        else if (variable_struct_exists(data, "error_description")) err = data.error_description;
    }
    status_text = (err != "") ? err : "Registration failed. HTTP " + string(http_status);
    show_debug_message("Register failed: HTTP " + string(http_status) + " " + result_text);
}
