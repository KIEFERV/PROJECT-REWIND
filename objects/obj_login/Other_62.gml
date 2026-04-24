/// Other_62 (Async HTTP) — obj_login
/// Handles Supabase signInWithPassword response.
/// Supabase returns: { access_token, user: { id, email, user_metadata: { username, role } } }

if (!ds_map_exists(async_load, "id")) exit;
if (async_load[? "id"] != login_request_id) exit;

var http_status = async_load[? "status"];
var result_text = async_load[? "result"];

if (http_status == 200) {
    var data = json_parse(result_text);

    if (is_struct(data) && variable_struct_exists(data, "access_token")) {
        global.auth_token = data.access_token;

        // Extract user info
        if (variable_struct_exists(data, "user")) {
            var u = data.user;
            global.user_id = variable_struct_exists(u, "id") ? u.id : "";

            // Username stored in user_metadata (set during registration)
            if (variable_struct_exists(u, "user_metadata")) {
                var meta = u.user_metadata;
                global.username  = variable_struct_exists(meta, "username") ? meta.username : u.email;
                global.user_role = variable_struct_exists(meta, "role")     ? meta.role     : "player";
            } else {
                global.username  = variable_struct_exists(u, "email") ? u.email : "";
                global.user_role = "player";
            }
        }

        status_text = "Login successful! Welcome, " + global.username + ".";
        show_debug_message("Logged in: " + global.username + " id=" + global.user_id);
        room_goto(rm_menu);
    } else {
        status_text = variable_struct_exists(data, "error_description")
            ? data.error_description
            : "Login failed.";
    }
} else {
    // Try to parse error message from Supabase
    var err = "";
    try {
        var data = json_parse(result_text);
        if (is_struct(data) && variable_struct_exists(data, "error_description"))
            err = data.error_description;
        else if (is_struct(data) && variable_struct_exists(data, "msg"))
            err = data.msg;
    } catch (_e) {}
    status_text = (err != "") ? err : "Login failed. Check your credentials.";
    show_debug_message("Login failed: HTTP " + string(http_status) + " " + result_text);
}
