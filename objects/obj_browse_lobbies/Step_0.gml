if (array_length(lobbies) > 0) {
    if (keyboard_check_pressed(vk_down)) {
        selected_index += 1;
        if (selected_index >= array_length(lobbies)) selected_index = array_length(lobbies) - 1;
    }

    if (keyboard_check_pressed(vk_up)) {
        selected_index -= 1;
        if (selected_index < 0) selected_index = 0;
    }
	
	if (keyboard_check_pressed(vk_escape)) {
    room_goto(rm_menu);
}

    if (keyboard_check_pressed(vk_enter)) {
        if (global.auth_token == "") {
            status_text = "You must login first.";
        } else {
            var lobby_id = lobbies[selected_index].id;

            join_request_id = http_request(
                base_url + "/api/lobbies/" + string(lobby_id) + "/join",
                "POST",
                "Content-Type: application/json\r\nAuthorization: Bearer " + global.auth_token + "\r\n",
                "{}"
            );

            status_text = "Joining lobby...";
        }
    }
}
