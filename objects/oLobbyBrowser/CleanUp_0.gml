/// CleanUp_0 — oLobbyBrowser

cleanup_lobby_list();
if (ds_exists(lobby_list, ds_type_list))
    ds_list_destroy(lobby_list);

if (lobby_socket >= 0) network_destroy(lobby_socket);
if (game_socket  >= 0) network_destroy(game_socket);
