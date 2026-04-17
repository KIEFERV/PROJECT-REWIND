eventList = [
	"none",
	"wind",
	"solar_flare",
	"rain",
	"snow",
	"storm"
];

event_current = eventList[0];
//Wind Event Settings
event_wind_dir = random_range(1, 360);
event_wind_power = random_range(0.5, 1.25);

//Solar Flare Event Settings

// Rain Event Settings

//Snow Eventt Settings

//alarm[0] = game_get_speed(gamespeed_fps* 10);

function event_swap(){
	event_current = eventList[random(4)];
	show_debug_message(event_current);
	if(event_current == "wind"){
		show_debug_message(event_wind_power);
	}
}