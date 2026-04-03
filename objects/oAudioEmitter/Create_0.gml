///@description create audio emitter

audio_falloff_set_model(audio_falloff_linear_distance);

// defaults
if (!variable_instance_exists(id, "pitch_min")) pitch_min = 1;
if (!variable_instance_exists(id, "pitch_max")) pitch_max = 1;

if (!variable_instance_exists(id, "volume_min")) volume_min = 1;
if (!variable_instance_exists(id, "volume_max")) volume_max = 1;

if (!variable_instance_exists(id, "falloff_ref")) falloff_ref = 50;
if (!variable_instance_exists(id, "falloff_max")) falloff_max = 1000;
if (!variable_instance_exists(id, "falloff_factor")) falloff_factor = 100;

if (!variable_instance_exists(id, "priority")) priority = 0;


//choose variant
if (is_array(sound)){
	sound_to_play = sound[irandom(array_length(sound)-1)];
}else{
	sound_to_play = sound;
}

//random pitch
var pitch = random_range(pitch_min, pitch_max);

//random gain
var gain = random_range(volume_min, volume_max);

//play positional audio
audio_id = audio_play_sound_at(
	sound_to_play,
	x, y, 0,
	falloff_ref,
	falloff_max,
	falloff_factor,
	false,
	priority,
	gain,
	0,
	pitch
);