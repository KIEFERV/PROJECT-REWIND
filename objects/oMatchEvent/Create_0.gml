eventList = ["none", "wind", "solar_flare", "rain"];
event_current = eventList[0];
event_wind = false;
event_wind_dir = random_range(1, 360);
event_wind_power = random_range(0.5, 1);

event_solar_flare = false;

event_rain = false;

//alarm[0] = game_get_speed(gamespeed_fps* 10);

