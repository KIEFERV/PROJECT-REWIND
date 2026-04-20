

room_speed = 60;

global.POWER_FIRE_RATE     = "fire_rate";
global.POWER_MOVE_SPEED    = "move_speed";
global.POWER_RICOCHET      = "ricochet";
global.POWER_COVER         = "cover";
global.POWER_GRAVITY_SHOT  = "gravity_shot";

//USER GLOBALS (safe defaults)
if (!variable_global_exists("auth_token")) global.auth_token = "";
if (!variable_global_exists("username")) global.username = "";
if (!variable_global_exists("user_role")) global.user_role = "";
if (!variable_global_exists("primary_weapon")) global.primary_weapon = "pistol";
if (!variable_global_exists("secondary_weapon")) global.secondary_weapon = "shotgun";


//MATCH STATS 
global.match_kills = 0;
global.match_deaths = 0;
global.match_time_seconds = 0;

// internal timer for tracking seconds
time_step_counter = 0;

//SERVER
//base_url = "http://localhost:8080";
//stats_request_id = -1;


// debug toggle
//debug_mode = true;