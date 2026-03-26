if (ds_map_exists(async_load, "id")) {
    var req_id = async_load[? "id"];
    var http_status = async_load[? "status"];
    var result_text = async_load[? "result"];

    if (req_id == browse_request_id) {
        var data = json_parse(result_text);

        if (http_status == 200 && is_struct(data) && data.ok) {
            lobbies = data.lobbies;
            status_text = "Loaded " + string(array_length(lobbies)) + " lobbies.";
            selected_index = 0;
        } else {
            status_text = "Failed to load lobbies.";
        }
    }

    if (req_id == join_request_id) {
        var join_data = json_parse(result_text);

        if (http_status == 200 && is_struct(join_data) && join_data.ok) {
            status_text = "Joined lobby successfully.";
        } else {
            if (is_struct(join_data) && variable_struct_exists(join_data, "message")) {
                status_text = join_data.message;
            } else {
                status_text = "Failed to join lobby.";
            }
        }
    }
}