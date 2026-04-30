/// Create_0 — obj_leaderboard
/// Fetches player stats directly from Supabase profiles table.
/// Sorted by wins desc, then kills desc.

leaderboard_request_id = -1;
leaderboard_data       = [];
status_text            = "Loading leaderboard...";
selected_row           = -1;
button_w               = 140;
button_h               = 40;
hover_back             = false;
hover_refresh          = false;

// Fetch from Supabase profiles table
// Returns: user_id, username, wins, kills, deaths ordered by wins desc
var _headers = ds_map_create();
ds_map_add(_headers, "apikey",         SUPABASE_ANON_KEY);
ds_map_add(_headers, "Authorization",  "Bearer " + SUPABASE_ANON_KEY);
ds_map_add(_headers, "Content-Type",   "application/json");

leaderboard_request_id = http_request(
    SUPABASE_URL_AUTH + "/rest/v1/profiles"
    + "?select=username,wins,kills,deaths"
    + "&order=wins.desc,kills.desc"
    + "&limit=20",
    "GET",
    _headers,
    ""
);
ds_map_destroy(_headers);
