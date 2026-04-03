base_url = "http://localhost:8080";

status_text = "Loading lobbies...";
lobbies = [];
selected_index = 0;

browse_request_id = http_get(base_url + "/api/lobbies");
join_request_id = -1;
last_char_used = "";