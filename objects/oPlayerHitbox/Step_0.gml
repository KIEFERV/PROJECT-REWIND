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



//move the player
x += xSpd;
y += ySpd;


//raycasting test



