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