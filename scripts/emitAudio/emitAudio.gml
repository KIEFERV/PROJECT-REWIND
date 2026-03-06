function emitAudio(_x, _y, sfx){
    instance_create_layer(_x, _y, "AudioLayer", oAudioEmitter,{
        sound: sfx,

        // pitch variation
        pitch_min: 0.9,
        pitch_max: 1.1,

        // volume variation
        volume_min: 0.8,
        volume_max: 1.0,

        // distance falloff
        falloff_ref: 50, //distance where sound is full volume
		falloff_max: 1000, //distance where sound reahes 0 volume
		falloff_factor: 1, //how quickly sound fades
		
		priority: 0
    });
}