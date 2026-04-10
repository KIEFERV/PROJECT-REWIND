function scr_game(){
if (global.auth_token == "") {
    if (debug_mode) show_debug_message("No token, skipping stat upload");
    return;
}

var body = json_stringify({
    kills: global.match_kills,
    deaths: global.match_deaths,
    time_played_seconds: global.match_time_seconds,
    token: global.auth_token
});

stats_request_id = http_request(
    base_url + "/api/stats/update",
    "POST",
    "Content-Type: application/json\r\n",
    body
);

if (debug_mode) {
    show_debug_message("Sending stats: " + body);
}
}