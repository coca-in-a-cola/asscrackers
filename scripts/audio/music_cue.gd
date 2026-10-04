class_name MusicCue
extends Resource

@export var id: StringName
@export var tracks: Array[AudioStream] = []
@export var repeat := true
@export_range(0.05, 4.0) var crossfade_seconds := 0.75
@export_range(0.05, 4.0) var transition_seconds := 1.5

func valid() -> bool:
	if id.is_empty() or tracks.is_empty() or not is_finite(crossfade_seconds) or crossfade_seconds <= 0.0 or not is_finite(transition_seconds) or transition_seconds <= 0.0:
		return false
	for stream in tracks:
		if stream == null or stream.get_length() <= 0.0:
			return false
	return true
