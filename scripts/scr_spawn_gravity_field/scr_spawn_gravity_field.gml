function scr_spawn_gravity_field(){
var _x = argument0;
var _y = argument1;
var _radius = argument2;
var _duration = argument3;
var _pull = argument4;
var _owner = argument5;

//function scr_spawn_gravity_field(){
//var gx = argument0;
//var gy = argument1;
//var gradius = argument2;
//var gduration = argument3;
//var gpull = argument4;
//var gowner = argument5;

var g = instance_create_layer(_x, _y, "layer_instances", obj_gravity_field);
//var g = instance_create_layer(gx, gy, "layer_instances", obj_gravity_field);
g.radius = _radius;
g.life = _duration;
g.pull_strength = _pull;
g.owner = _owner;
}