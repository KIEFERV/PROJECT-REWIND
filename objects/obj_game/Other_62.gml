if (ds_map_exists(async_load, "id")) {
    var req_id = async_load[? "id"];

    if (req_id == stats_request_id) {
        var status = async_load[? "status"];
        var result = async_load[? "result"];

        if (debug_mode) {
            show_debug_message("Stats response: " + string(result));
        }

        if (status == 200) {
            if (debug_mode) show_debug_message("Stats updated successfully");
        } else {
            show_debug_message("Stats update failed");
        }
    }
}