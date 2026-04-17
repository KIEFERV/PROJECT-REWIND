global.ip_address = "127.0.0.1";
global.port = 7777;
global.shadow_view_radius = 1058; //distance that shadows will be cast ingame
global.my_pid = 0;
global.socket = -1;
global.serverPath = "C:/Users/Alex/Documents/Github/PROJECT-REWIND/server/main.exe";
//testpath = working_directory + "server\\main.exe";
//show_debug_message( "WORKING DIRECTORY IS: " + working_directory);
execute_shell_simple(global.serverPath);