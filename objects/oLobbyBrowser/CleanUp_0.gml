/// CleanUp_0 — oLobbyBrowser

// Free lobby list entries
cleanup_lobby_list();
if (ds_exists(lobby_list, ds_type_list))
    ds_list_destroy(lobby_list);

// Destroy DB socket if not already done
if (lobby_socket >= 0)
    network_destroy(lobby_socket);

// Destroy game poll socket if not already handed off to rLobby
// (game_socket = -1 means it was handed to global.socket successfully)
if (game_socket >= 0)
    network_destroy(game_socket);
