base_url = "http://localhost:8080";

leaderboard_request_id = -1;
leaderboard_data = [];

status_text = "Loading leaderboard...";
selected_row = -1;

button_w = 140;
button_h = 40;
hover_back = false;

// request leaderboard immediately
leaderboard_request_id = http_get(base_url + "/api/leaderboard");