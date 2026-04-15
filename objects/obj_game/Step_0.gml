time_step_counter += 1;

if (time_step_counter >= room_speed) {
    global.match_time_seconds += 1;
    time_step_counter = 0;
}