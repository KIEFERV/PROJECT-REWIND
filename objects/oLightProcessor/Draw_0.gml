var lx = oPlayerModel.x;
var ly = oPlayerModel.y;
var rad = 256;


vertex_begin(VBuffer, VertexFormat);

with (oLightWall){
	
	var x_width_size = x + sprite_width;
	var y_length_size = y + sprite_height;
	//for(var yy=starty;yy<=endy;yy++){
		//for(var xx=startx;xx<=endx;xx++){
	
    if ((point_distance(x, y, lx, ly) <= rad + sprite_width)
	||(point_distance(x_width_size, y, lx, ly)<= rad + sprite_width)
	||(point_distance(x, y_length_size, lx, ly)<= rad + sprite_width)
	||(point_distance(x_width_size, y_length_size, lx, ly)<= rad + sprite_width)){
	
	//DEBUG - draw a yellow box to show the render range
	if(oPlayerHitbox.debug_menu == true){
		draw_circle(lx, ly, rad+sprite_width, true);
	}


    // Bounding box
    var px1 = bbox_left;
    var py1 = bbox_top;
    var px2 = bbox_right;
    var py2 = bbox_bottom;

    // Top edge
    if (!SignTest(px1,py1, px2,py1, lx,ly))
        ProjectShadow(other.VBuffer, px1,py1, px2,py1, lx,ly);

    // Right edge
    if (!SignTest(px2,py1, px2,py2, lx,ly))
        ProjectShadow(other.VBuffer, px2,py1, px2,py2, lx,ly);

    // Bottom edge
    if (!SignTest(px2,py2, px1,py2, lx,ly))
        ProjectShadow(other.VBuffer, px2,py2, px1,py2, lx,ly);

    // Left edge
    if (!SignTest(px1,py2, px1,py1, lx,ly))
        ProjectShadow(other.VBuffer, px1,py2, px1,py1, lx,ly);
		
	//DEBUG - draw boxes around objects currently casting shadows
	if(oPlayerHitbox.debug_menu == true){
			
		draw_rectangle(bbox_left, bbox_top, bbox_right, bbox_bottom, false);
		}
	}
		
}

vertex_end(VBuffer);
vertex_submit(VBuffer, pr_trianglelist, -1);