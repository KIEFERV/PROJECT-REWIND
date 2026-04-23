/// CleanUp_0 — oLobbyBrowser

// Free online lobby list
cleanup_lobby_list();
if (ds_exists(lobby_list, ds_type_list))
    ds_list_destroy(lobby_list);

// Free LAN host maps
close_disc_socket();
if (ds_exists(lan_hosts,      ds_type_map)) ds_map_destroy(lan_hosts);
if (ds_exists(lan_host_times, ds_type_map)) ds_map_destroy(lan_host_times);

// Destroy sockets
if (lobby_socket >= 0) network_destroy(lobby_socket);
if (game_socket  >= 0) network_destroy(game_socket);
// disc_socket no longer used — discovery runs on lobby_socket
