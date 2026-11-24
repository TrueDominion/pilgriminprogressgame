class_name MovementData
extends RefCounted
## Typed access to res://data/movement.json. One instance per movement set.

const PATH := "res://data/movement.json"

var run_speed: float
var ground_accel: float
var ground_decel: float
var air_accel: float
var jump_height: float
var rise_gravity: float
var fall_gravity: float
var max_fall_speed: float
var jump_cut_multiplier: float
var double_jump: bool
var double_jump_height: float
var heavy_landing_fall_px: float
var heavy_landing_recovery_s: float
var mud_sink_speed: float
var mud_move_multiplier: float
var hitbox: Vector2


static func load_all() -> Dictionary:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	assert(raw is Dictionary, "movement.json missing or invalid")
	var sets := {}
	for set_name: String in ["burdened", "free"]:
		var m := MovementData.new()
		var d: Dictionary = raw[set_name]
		m.run_speed = d["run_speed"]
		m.ground_accel = d["ground_accel"]
		m.ground_decel = d["ground_decel"]
		m.air_accel = d["air_accel"]
		m.jump_height = d["jump_height"]
		m.rise_gravity = d["rise_gravity"]
		m.fall_gravity = d["fall_gravity"]
		m.max_fall_speed = d["max_fall_speed"]
		m.jump_cut_multiplier = d["jump_cut_multiplier"]
		m.double_jump = d["double_jump"]
		m.double_jump_height = d.get("double_jump_height", 0.0)
		m.heavy_landing_fall_px = d["heavy_landing_fall_px"]
		m.heavy_landing_recovery_s = d["heavy_landing_recovery_s"]
		m.mud_sink_speed = d["mud_sink_speed"]
		m.mud_move_multiplier = d["mud_move_multiplier"]
		var hb: Dictionary = raw["hitbox"][set_name]
		m.hitbox = Vector2(hb["w"], hb["h"])
		sets[set_name] = m
	sets["shared"] = raw["shared"]
	sets["hope"] = raw["hope"]
	return sets


func jump_velocity() -> float:
	return -sqrt(2.0 * rise_gravity * jump_height)


func double_jump_velocity() -> float:
	return -sqrt(2.0 * rise_gravity * double_jump_height)
