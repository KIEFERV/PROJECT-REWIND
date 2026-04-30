/// Other_62 (Async HTTP) — obj_leaderboard
/// Handles Supabase profiles table response.
/// Response is a JSON array: [{ username, wins, kills, deaths }, ...]

if (!ds_map_exists(async_load, "id")) exit;
if (async_load[? "id"] != leaderboard_request_id) exit;

var http_status = async_load[? "status"];
var result_text = async_load[? "result"];
if (is_undefined(result_text)) result_text = "";

if (result_text == "") {
    status_text = "No response from server.";
    exit;
}

// Supabase returns a raw JSON array for GET requests
var data = json_parse(result_text);

if (is_array(data) && array_length(data) > 0) {
    leaderboard_data = data;
    status_text      = "Loaded " + string(array_length(data)) + " players.";
} else if (is_array(data) && array_length(data) == 0) {
    leaderboard_data = [];
    status_text      = "No players found.";
} else {
    leaderboard_data = [];
    status_text      = "Failed to load. HTTP " + string(http_status);
    show_debug_message("Leaderboard error: " + result_text);
}
