extends Node
## Player settings (autoload `Settings`), saved to user://settings.json and applied at start.
## Global, not per save slot (gdd.md 12). More options (text size, shake, touch layout)
## join here in phase 4.

const PATH := "user://settings.json"

var music := 0.8     # 0..1
var effects := 1.0   # 0..1
var assist := false  # Pilgrim's Aid (gdd.md 5): hazards cost no Hope


func _ready() -> void:
	if FileAccess.file_exists(PATH):
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		if d is Dictionary:
			music = clampf(float(d.get("music", music)), 0.0, 1.0)
			effects = clampf(float(d.get("effects", effects)), 0.0, 1.0)
			assist = bool(d.get("assist", assist))
	apply.call_deferred()


func apply() -> void:
	_set_bus("Music", music)
	_set_bus("SFX", effects)


func _set_bus(bus: String, v: float) -> void:
	var i := AudioServer.get_bus_index(bus)
	if i == -1:
		return
	AudioServer.set_bus_mute(i, v <= 0.001)
	AudioServer.set_bus_volume_db(i, linear_to_db(maxf(v, 0.001)) + (-4.0 if bus == "Music" else 0.0))


func save() -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"music": music, "effects": effects, "assist": assist}))
