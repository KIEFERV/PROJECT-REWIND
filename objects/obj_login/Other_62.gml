/// Other_62 (Async HTTP) — obj_login
/// Handles Supabase signInWithPassword response.
/// Supabase returns: { access_token, user: { id, email, user_metadata: { username, role } } }

if (!ds_map_exists(async_load, "id")) exit;
if (async_load[? "id"] != login_request_id) exit;

var http_status = async_load[? "status"];
var result_text = async_load[? "result"];

// Parse the response regardless of status code —
// GML sometimes returns 0 even on success when the body is large
var data = json_parse(result_text);

// Check for access_token — this is the definitive success indicator
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

        // Fallback username to email if not set in metadata
        if (global.username == "" && variable_struct_exists(u, "email"))
            global.username = u.email;
        if (global.user_role == "") global.user_role = "player";
    }

    status_text = "Login successful! Welcome, " + global.username + ".";
    show_debug_message("Logged in: " + global.username + " id=" + global.user_id);
    room_goto(rm_menu);

} else if (http_status == 200 || http_status == 0) {
    // Response came back but no access_token — likely an error message
    var err = "";
    if (is_struct(data)) {
        if (variable_struct_exists(data, "error_description")) err = data.error_description;
        else if (variable_struct_exists(data, "msg"))          err = data.msg;
        else if (variable_struct_exists(data, "message"))      err = data.message;
    }
    status_text = (err != "") ? err : "Login failed.";
    show_debug_message("Login error: " + result_text);

} else {
    status_text = "Login failed. HTTP " + string(http_status);
    show_debug_message("Login failed: HTTP " + string(http_status));
}
