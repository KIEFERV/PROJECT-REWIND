if (ds_map_exists(async_load, "id")) {
    var req_id = async_load[? "id"];

    if (req_id == login_request_id) {
        var http_status = async_load[? "status"];
        var result_text = async_load[? "result"];

        if (http_status != 200) {
            status_text = "Login failed. HTTP " + string(http_status);
            exit;
        }

        var data = json_parse(result_text);

        if (is_struct(data)) {
            if (data.ok) {
                global.auth_token = data.token;
                global.username = data.user.username;
                global.user_role = data.user.role;

                status_text = "Login successful!";

                room_goto(rm_menu);
            } else {
                status_text = data.message;
            }
        } else {
            status_text = "Bad server response.";
        }
    }
}