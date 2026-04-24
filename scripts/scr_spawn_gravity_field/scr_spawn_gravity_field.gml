function scr_spawn_gravity_field(){
var gx = argument0;
var gy = argument1;
var gradius = argument2;
var gduration = argument3;
var gpull = argument4;
var gowner = argument5;

var g = instance_create_layer(gx, gy, "layer_instances", obj_gravity_field);
g.radius = gradius;
g.life = gduration;
g.pull_strength = gpull;
g.owner = gowner;
}