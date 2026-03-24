// Async - Networking Event
if (async_load[? "type"] == network_type_data) {
    var buf = async_load[? "buffer"];
    buffer_seek(buf, buffer_seek_start, 0);
    var msg = buffer_read(buf, buffer_string);
    show_debug_message("Server says: " + msg);
}