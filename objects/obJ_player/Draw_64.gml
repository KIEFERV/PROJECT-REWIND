var yy = 20;
var keys = ds_map_keys_to_array(powerups);

draw_set_color(c_white);
draw_text(20, yy, "Active Powers:");
yy += 20;

for (var i = 0; i < array_length(keys); i++) {
    var k = keys[i];
    draw_text(20, yy, string(k));
    yy += 18;
}
raw_set_color(c_white);
draw_text(20, 20, "Kills: " + string(global.match_kills));
draw_text(20, 40, "Deaths: " + string(global.match_deaths));
draw_text(20, 60, "Time: " + string(global.match_time_seconds));