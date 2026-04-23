/// Other_62 (Async HTTP) — obj_register
/// Handles Supabase signUp response.

if (!ds_map_exists(async_load, "id")) exit;
if (async_load[? "id"] != register_request_id) exit;

var http_status = async_load[? "status"];
var result_text = async_load[? "result"];

if (http_status == 200) {
    var data = json_parse(result_text);

    // Supabase returns the user object on success
    if (is_struct(data) && variable_struct_exists(data, "id")) {
        status_text = "Account created! Please check your email to confirm, then log in.";
        show_debug_message("Registered: " + email_text);
        room_goto(rm_login);
    } else {
        var msg = "";
        if (is_struct(data) && variable_struct_exists(data, "msg"))
            msg = data.msg;
        status_text = (msg != "") ? msg : "Registration failed.";
    }
} else {
    var err = "";
    try {
        var data = json_parse(result_text);
        if (is_struct(data) && variable_struct_exists(data, "msg"))
            err = data.msg;
        else if (is_struct(data) && variable_struct_exists(data, "error_description"))
            err = data.error_description;
    } catch (_e) {}
    status_text = (err != "") ? err : "Registration failed. HTTP " + string(http_status);
    show_debug_message("Register failed: " + result_text);
}
