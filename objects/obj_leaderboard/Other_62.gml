if (ds_map_exists(async_load, "id")) {
    var req_id = async_load[? "id"];

    if (req_id == leaderboard_request_id) {
        var http_status = async_load[? "status"];
        var result_text = async_load[? "result"];

        var data = json_parse(result_text);

        if (http_status == 200 && is_struct(data) && data.ok) {
            leaderboard_data = data.leaderboard;
            status_text = "Leaderboard loaded.";
        } else {
            status_text = "Failed to load leaderboard.";
        }
    }
}