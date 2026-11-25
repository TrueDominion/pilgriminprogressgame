extends Node
## Music and sound effects (autoload `Audio`). Files are looked up by name:
##   res://assets/audio/music/<name>.ogg   (looped)
##   res://assets/audio/sfx/<name>.ogg
## A missing file is skipped silently, so the game runs before every sound exists.
## Buses: Music and SFX under Master, so Settings can set each level (gdd.md 13).

const MUSIC_DIR := "res://assets/audio/music/"
const SFX_DIR := "res://assets/audio/sfx/"
const POOL := 8

## Tests turn this off: headless runs have no audio mixing, so playing sounds there
## would leave playbacks unreleased at exit.
var enabled := true
var _music: AudioStreamPlayer
var _music_name := ""
var _pool: Array[AudioStreamPlayer] = []
var _cache := {}
var _next := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for bus in ["Music", "SFX"]:
		if AudioServer.get_bus_index(bus) == -1:
			AudioServer.add_bus()
			var i := AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, bus)
			AudioServer.set_bus_send(i, "Master")
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), -4.0)
	_music = AudioStreamPlayer.new()
	_music.bus = "Music"
	add_child(_music)
	for i in POOL:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_pool.append(p)


func _load(path: String) -> AudioStream:
	if _cache.has(path):
		return _cache[path]
	var s: AudioStream = load(path) if ResourceLoader.exists(path) else null
	_cache[path] = s
	return s


## Plays a sound effect. pitch_jitter varies repeated sounds (footsteps) slightly;
## pitch shifts the whole sound (mud bubbles rise as Christian sinks).
func sfx(name: String, volume_db := 0.0, pitch_jitter := 0.0, pitch := 1.0) -> void:
	if not enabled:
		return
	var s := _load(SFX_DIR + name + ".ogg")
	if s == null:
		return
	var p := _pool[_next]
	_next = (_next + 1) % POOL
	p.stream = s
	p.volume_db = volume_db
	p.pitch_scale = pitch + randf_range(-pitch_jitter, pitch_jitter)
	p.play()


## Starts a looping track, fading from whatever was playing.
func music(name: String, fade := 1.0) -> void:
	if not enabled:
		return
	if name == _music_name:
		return
	_music_name = name
	var s := _load(MUSIC_DIR + name + ".ogg")
	var t := create_tween()
	if _music.playing:
		t.tween_property(_music, "volume_db", -40.0, fade * 0.5)
	t.tween_callback(func() -> void:
		_music.stop()
		if s == null:
			return
		if s is AudioStreamOggVorbis:
			(s as AudioStreamOggVorbis).loop = true
		_music.stream = s
		_music.volume_db = -40.0
		_music.play())
	t.tween_property(_music, "volume_db", 0.0, fade * 0.5)


## Stops everything and releases the streams (used before quitting).
func stop_all() -> void:
	_music_name = ""
	_music.stop()
	_music.stream = null
	for p in _pool:
		p.stop()
		p.stream = null
	_cache.clear()


func _exit_tree() -> void:
	stop_all()
