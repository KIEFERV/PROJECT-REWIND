///@description 

//get inputs
rightKey = keyboard_check(ord("D"));
leftKey = keyboard_check(ord("A"));
upKey = keyboard_check(ord("W"));
downKey = keyboard_check(ord("S"));

//get x and y speeds
xSpd = (rightKey - leftKey) * moveSpd;
ySpd = (downKey - upKey) * moveSpd;


//player collision
//X axis
if place_meeting(x + xSpd, y, oWall){
	xSpd = 0;	
}
//y axis
if place_meeting(x, y + ySpd, oWall){
	ySpd = 0;	
}

if place_meeting(x + xSpd, y, oDestructibleWall){
	xSpd = 0;	
}
//y axis
if place_meeting(x, y + ySpd, oDestructibleWall){
	ySpd = 0;	
}



//move the player
x += xSpd;
y += ySpd;


if(keyboard_check(vk_shift)){
	moveSpd = sprintSpd;
}else{
	moveSpd = 2;
}


//raycasting test



