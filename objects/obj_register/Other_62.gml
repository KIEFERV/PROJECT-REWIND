/// Other_62 (Async HTTP) — obj_register
/// Handles Supabase signUp response.
/// GML sometimes returns HTTP status 0 even on success when body is large,
/// so we check for the "id" field directly as the success indicator.

if (!ds_map_exists(async_load, "id")) exit;
if (async_load[? "id"] != register_request_id) exit;

var http_status = async_load[? "status"];
var result_text = async_load[? "result"];
if (is_undefined(result_text)) result_text = "";

// Parse response regardless of status code
if (result_text == "") {
    status_text = "No response from server.";
    exit;
}

var data = json_parse(result_text);

// Check for user id — this is the definitive success indicator
if (is_struct(data) && variable_struct_exists(data, "id")) {
    status_text = "Account created! You can now log in.";
    show_debug_message("Registered successfully: " + email_text);
    room_goto(rm_login);
} else {
    // Parse error message
    var err = "";
    if (is_struct(data)) {
        if (variable_struct_exists(data, "msg"))               err = data.msg;
        else if (variable_struct_exists(data, "message"))      err = data.message;
        else if (variable_struct_exists(data, "error_description")) err = data.error_description;
    }
    status_text = (err != "") ? err : "Registration failed. HTTP " + string(http_status);
    show_debug_message("Register failed: HTTP " + string(http_status) + " " + result_text);
}
