/// CleanUp_0 — oLobbyBrowser

cleanup_lobby_list();
if (ds_exists(lobby_list, ds_type_list))
    ds_list_destroy(lobby_list);

close_disc_socket();
if (ds_exists(lan_hosts,      ds_type_map)) ds_map_destroy(lan_hosts);
if (ds_exists(lan_host_times, ds_type_map)) ds_map_destroy(lan_host_times);

if (lobby_socket >= 0) network_destroy(lobby_socket);
if (game_socket  >= 0) network_destroy(game_socket);
// disc_socket not used in request-reply discovery mode
