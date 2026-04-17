//if (room == rInit){
//	room_goto(rLobby);
//}

if (keyboard_check_pressed(ord("P"))){
	room_goto(rLobby);	
}


/*
if (keyboard_check_pressed(ord("P"))){

//Create a buffer to tel lthe server to shut down


//var buf = buffer_create(16, buffer_fixed, 1);
		var buf = buffer_create(10, buffer_grow, 1);
		buffer_seek(buf, buffer_seek_start, 0);
		buffer_write(buf, buffer_u8, 4);         
		buffer_write(buf, buffer_f32, x); 
		
		var ip = global.ip_address,
			port = global.port;
		socket = global.socket;
		network_send_udp_raw(socket, ip, port, buf, buffer_tell(buf));
		
		buffer_delete(buf);


	show_debug_message("Closing Server");
	game_end()
}

if (ptype == 6){
	show_debug_message("Closing Server");
	game_end()
	exit;
}
*/