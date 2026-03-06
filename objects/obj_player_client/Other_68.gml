show_debug_message(json_encode(async_load)); //for receiving data from server

if(async_load[? "size"]>0){
    var buff = async_load[? "buffer"];
    buffer_seek(player_buffer, buffer_seek_start, 0);
    var response = buffer_read(buff, buffer_string)
    show_debug_message(response)
}