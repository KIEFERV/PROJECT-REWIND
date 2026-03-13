if (ds_map_exists(async_load, "id")) {
    var req_id = async_load[? "id"];

    if (req_id == create_lobby_request_id) {
        var http_status = async_load[? "status"];
        var result_text = async_load[? "result"];
        var data = json_parse(result_text);

        if (http_status == 200 && is_struct(data) && data.ok) {
            status_text = "Lobby created! ID: " + string(data.lobby_id);
        } else {
            if (is_struct(data) && variable_struct_exists(data, "message")) {
                status_text = data.message;
            } else {
                status_text = "Failed to create lobby.";
            }
        }
    }
}