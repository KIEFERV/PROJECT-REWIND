if (keyboard_check_pressed(ord("K"))){
	event_current = eventList[random(4)];
	show_debug_message(event_current);
	if(event_current == "wind"){
		show_debug_message(event_wind_power);
	}
}