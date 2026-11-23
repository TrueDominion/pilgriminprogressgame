extends Control
## Phase 0 placeholder scene. Proves the build, scaling and fonts work on every target.
## Replaced by the title screen in phase 2.

@onready var _info: Label = %Info


func _ready() -> void:
	_refresh()
	get_viewport().size_changed.connect(_refresh.call_deferred)


func _input(event: InputEvent) -> void:
	var start: bool = event.is_action_pressed("jump") or event.is_action_pressed("action") \
		or (event is InputEventScreenTouch and event.pressed) \
		or (event is InputEventMouseButton and event.pressed)
	if start:
		get_tree().change_scene_to_file("res://scenes/test_range.tscn")


func _refresh() -> void:
	var vp := get_viewport().get_visible_rect().size
	var win := DisplayServer.window_get_size()
	_info.text = "%s\nview %dx%d at %dx  window %dx%d\nsafe %s\n%s" % [
		Build.label(), vp.x, vp.y, ScreenFit.scale_factor, win.x, win.y,
		ScreenFit.safe_rect(), OS.get_name()]
