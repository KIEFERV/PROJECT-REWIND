///@description controls the cameras location
var xTo, yTo;
move_towards_point(mouse_x, mouse_y, 0);
xTo = oPlayerHitbox.x + lengthdir_x(min(96, distance_to_point(mouse_x, mouse_y)), direction);
yTo = oPlayerHitbox.y + lengthdir_y(min(96, distance_to_point(mouse_x, mouse_y)), direction);

x += (xTo-x)/25;
y += (yTo-y)/25;

view_xview = (view_wview/2) + x;
view_yview = (view_hview/2) + y;