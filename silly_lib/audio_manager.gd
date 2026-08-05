extends Node

signal bus_volume_changed(volume_db: float)
signal song_changed(song: AudioStream)
signal music_paused(song: AudioStream)
signal music_resumed(song: AudioStream)
signal music_stopped(song: AudioStream)
signal music_reset(song: AudioStream)

const BUS_MUSIC: String = "MSC"
const BUS_SFX: String = "SFX"
const MUTED: float = -80.0

var _music_muted: bool = false
var _sound_muted: bool = false
var _music_player_1: AudioStreamPlayer = AudioStreamPlayer.new()
var _music_player_2: AudioStreamPlayer = AudioStreamPlayer.new()
var _active_music_player: AudioStreamPlayer
var _music_time_stamp: float = 0.0
var _fade_tween: Tween

func _ready() -> void:
	_music_player_1.bus = BUS_MUSIC
	_music_player_2.bus = BUS_MUSIC
	add_child(_music_player_1)
	add_child(_music_player_2)
	_active_music_player = _music_player_1

### BUSES ###

func get_bus_volume(bus_name: String) -> float:
	var bus_index: int = AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		return 0.0
	return db_to_linear(AudioServer.get_bus_volume_db(bus_index))

func set_bus_volume(bus_name: String, linear_volume: float) -> void:
	var bus_index: int = AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		return
	var volume_db: float = linear_to_db(clamp(linear_volume, 0.0, 1.0))
	AudioServer.set_bus_volume_db(bus_index, volume_db)
	bus_volume_changed.emit(linear_volume)

func mute_bus(bus_name: String, value: bool) -> void:
	match bus_name:
		"MSC":
			_music_muted = value
		"SFX":
			_sound_muted = value

### MUSIC ###

func _change_song(song: AudioStream, fade_out_time: float = 0.0, fade_in_time: float = 0.0, crossfade: bool = false) -> void:
	if !song:
		push_warning("Requested invalid song.")
		return
	if _active_music_player.stream == song:
		return
	_reset_tween()
	_music_time_stamp = 0.0 if !_music_muted else MUTED
	var fading_out_player: AudioStreamPlayer = _active_music_player
	var fading_in_player: AudioStreamPlayer = \
			_music_player_1 if _active_music_player == _music_player_2 else _music_player_2
	fading_in_player.stop()
	fading_in_player.stream = song
	fading_in_player.volume_db = MUTED if fade_in_time > 0.0 or _music_muted else 0.0
	_init_fade_tween(fading_out_player, fade_out_time, fading_in_player, fade_in_time, crossfade)
	_active_music_player = fading_in_player
	_fade_tween.finished.connect(func():
		if fading_out_player == _active_music_player:
			return
		fading_out_player.stop()
		fading_out_player.stream = null
	)
	song_changed.emit(song)

func play_new_song(song: AudioStream, fade_out_time: float = 0.0, fade_in_time: float = 0.0) -> void:
	_change_song(song, fade_out_time, fade_in_time, false)

func crossfade_to_new_song(song: AudioStream, fade_time: float = 0.0) -> void:
	_change_song(song, fade_time, fade_time, true)

func get_current_song() -> AudioStream:
	return _active_music_player.stream

func is_music_playing() -> bool:
	return _active_music_player.playing

func is_music_fading() -> bool:
	return _fade_tween and _fade_tween.is_valid() and _fade_tween.is_running()

func pause_music() -> void:
	if !_active_music_player.stream or !_active_music_player.playing:
		return
	_music_time_stamp = _active_music_player.get_playback_position()
	music_paused.emit(_active_music_player.stream)
	_active_music_player.stop()

func resume_music() -> void:
	if !_active_music_player.stream or _active_music_player.playing:
		return
	_active_music_player.play(_music_time_stamp)
	music_resumed.emit(_active_music_player.stream)

func get_music_position() -> float:
	if !_active_music_player.stream:
		return 0.0
	return _active_music_player.get_playback_position()

func set_music_position(time_position: float) -> void:
	_music_time_stamp = time_position
	if !_active_music_player.stream:
		return
	_active_music_player.seek(time_position)

func stop_music(fade_out_time: float) -> void:
	_reset_tween()
	_fade_tween.tween_property(_active_music_player, "volume_db", MUTED, fade_out_time)
	_fade_tween.tween_callback(func():
		_active_music_player.stop()
		_active_music_player.stream = null
		_active_music_player.volume_db = 0.0
	)
	_music_time_stamp = 0.0
	music_stopped.emit(_active_music_player.stream)

func restart_music() -> void:
	if !_active_music_player.stream:
		return
	_music_time_stamp = 0.0
	_active_music_player.play(0.0)
	music_reset.emit(_active_music_player.stream)

func _reset_tween() -> void:
	if is_music_fading():
		_fade_tween.kill()
	_fade_tween = create_tween()
	_music_player_1.volume_db = 0.0
	_music_player_2.volume_db = 0.0

func _init_fade_tween(fading_out_player: AudioStreamPlayer, fade_out_time: float, fading_in_player: AudioStreamPlayer, fade_in_time: float, crossfade: bool) -> void:
	_fade_tween.set_parallel(crossfade)
	#fade out
	if fade_out_time > 0.0 and fading_out_player.playing:
		_fade_tween.tween_property(fading_out_player, "volume_db", MUTED, fade_out_time)
	else:
		fading_out_player.volume_db = MUTED
	#fade in
	if crossfade:
		fading_in_player.play()
	else:
		_fade_tween.tween_callback(fading_in_player.play)
	if fade_in_time > 0.0:
		_fade_tween.tween_property(fading_in_player, "volume_db", 0.0, fade_in_time)
	else:
		_fade_tween.tween_callback(func():
			fading_in_player.volume_db = 0.0
		)

### SOUND EFFECTS ###

func _play_sound(audio_stream_player: Node, sound: AudioStream, pitch_min: float = 0.95, pitch_max = 1.05) -> void:
	if !sound or _sound_muted:
		return
	if audio_stream_player is not AudioStreamPlayer \
			and audio_stream_player is not AudioStreamPlayer2D \
			and audio_stream_player is not AudioStreamPlayer3D:
		return
	audio_stream_player.bus = BUS_SFX
	add_child(audio_stream_player)
	audio_stream_player.stream = sound
	audio_stream_player.pitch_scale = randf_range(pitch_min, pitch_max)
	audio_stream_player.play()
	audio_stream_player.finished.connect(audio_stream_player.queue_free)

func play_sound(sound: AudioStream, pitch_min: float = 0.95, pitch_max: float = 1.05) -> void:
	_play_sound(AudioStreamPlayer.new(), sound, pitch_min, pitch_max)

func play_sound_flat(sound: AudioStream, pitch_scale: float) -> void:
	_play_sound(AudioStreamPlayer.new(), sound, pitch_scale, pitch_scale)

func play_sound_at_position_2D(sound: AudioStream, position: Vector2, pitch_min: float = 0.95, pitch_max: float = 1.05) -> void:
	var audio_stream_player: AudioStreamPlayer2D = AudioStreamPlayer2D.new()
	audio_stream_player.global_position = position
	_play_sound(audio_stream_player, sound, pitch_min, pitch_max)

func play_sound_at_node_2D(sound: AudioStream, node: Node2D, pitch_min: float = 0.95, pitch_max: float = 1.05) -> void:
	play_sound_at_position_2D(sound, node.global_position, pitch_min, pitch_max)

func play_sound_at_position_3D(sound: AudioStream, position: Vector3, pitch_min: float = 0.95, pitch_max: float = 1.05) -> void:
	var audio_stream_player: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
	audio_stream_player.global_position = position
	_play_sound(audio_stream_player, sound, pitch_min, pitch_max)

func play_sound_at_node_3D(sound: AudioStream, node: Node3D, pitch_min: float = 0.95, pitch_max: float = 1.05) -> void:
	play_sound_at_position_3D(sound, node.global_position, pitch_min, pitch_max)
