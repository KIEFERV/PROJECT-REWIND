stats_timer += 1;

if (stats_timer >= room_speed) {
    global.match_time_seconds += 1;
    stats_timer = 0;
}

global.match_kills += 1;

global.match_deaths += 1;

//when match ends 
//global.match_kills = 0;
//global.match_deaths = 0;
//global.match_time_seconds = 0;