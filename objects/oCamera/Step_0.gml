///@description controls the cameras location
var xTo, yTo;

//make the camera attempt to follow the mouse
move_towards_point(mouse_x, mouse_y, 0);
xTo = oPlayerHitbox.x + lengthdir_x(min(100, distance_to_point(mouse_x, mouse_y)), direction);
yTo = oPlayerHitbox.y + lengthdir_y(min(100, distance_to_point(mouse_x, mouse_y)), direction);

x += (xTo-x)/15;
y += (yTo-y)/15;

//speed of the camera movement
view_xview = (view_wview/2) + x;
view_yview = (view_hview/2) + y;

view_xview = clamp(view_xview, 0, room_width-view_wview);
view_yview = clamp(view_yview, 0, room_width-view_hview);

//make the view follow the camera
camera_set_view_target(view_camera[0], oCamera);