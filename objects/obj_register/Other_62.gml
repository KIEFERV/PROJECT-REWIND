if (ds_map_exists(async_load, "id")) {
    var req_id = async_load[? "id"];

    if (req_id == register_request_id) {
        var http_status = async_load[? "status"];
        var result_text = async_load[? "result"];

        var data = json_parse(result_text);

        if (http_status == 200 && is_struct(data) && data.ok) {
            status_text = "Registration successful! Returning to login...";
            room_goto(rm_login);
        } else {
            if (is_struct(data) && variable_struct_exists(data, "message")) {
                status_text = data.message;
            } else {
                status_text = "Registration failed.";
            }
        }
    }
}