function scr_spawn_gravity_field(){
var _x = argument0;
var _y = argument1;
var _radius = argument2;
var _duration = argument3;
var _pull = argument4;
var _owner = argument5;

var g = instance_create_layer(_x, _y, "Instances", obj_gravity_field);
g.radius = _radius;
g.life = _duration;
g.pull_strength = _pull;
g.owner = _owner;
}