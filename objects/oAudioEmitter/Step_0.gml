//if(state == 0){
	//audio_play_sound_on(s_emit, sfxPop, true, 1);
	//state = 1;
//}else if(state == 1){
	//instance_destroy();
//}

if(!audio_is_playing(audio_id)){
	instance_destroy();
}