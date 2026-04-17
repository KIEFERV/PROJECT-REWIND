/// CleanUp_0 — oLobbyBrowser

cleanup_lobby_list();

if (ds_exists(lobby_list, ds_type_list))
    ds_list_destroy(lobby_list);

// Guard: socket may already be destroyed if we transitioned via join-approved path
if (db_socket >= 0)
    network_destroy(db_socket);
