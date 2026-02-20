function emitAudio(instance_id, id){
	emitter1 = audio_emitter_create(); //create an audio emitter
	emitter1_bus = audio_bus_create(); //create an audio bus
	audio_emitter_bus(emitter1, emitter1_bus);
	audio_play_sound_on(emitter1, snd_Ambience, true, 100);
	
}