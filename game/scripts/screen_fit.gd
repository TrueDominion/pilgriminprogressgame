extends Node
## Pixel-perfect screen fit, available as the `ScreenFit` autoload.
##
## Picks the largest whole-number scale at which the minimum view (480x270) still fits,
## then grows the view in game pixels so it fills the screen. Wider or taller screens
## see more of the world; nothing is ever stretched. The view is capped at MAX_VIEW so
## level art never has to cover an unbounded area (iPad and ultrawide get thin bars).
## Values come from res://data/display.json so they can be tuned without code changes.

const CONFIG_PATH := "res://data/display.json"

var min_view := Vector2i(480, 270)
var max_view := Vector2i(720, 416)
var scale_factor: int = 1
var view_size := Vector2i(480, 270)


func _ready() -> void:
	_load_config()
	get_tree().root.size_changed.connect(_fit)
	_fit()


func _load_config() -> void:
	if not FileAccess.file_exists(CONFIG_PATH):
		return
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	if data is Dictionary:
		if data.has("min_view"):
			min_view = Vector2i(data["min_view"][0], data["min_view"][1])
		if data.has("max_view"):
			max_view = Vector2i(data["max_view"][0], data["max_view"][1])


func _fit() -> void:
	var win: Window = get_tree().root
	var size: Vector2i = win.size
	if size.x <= 0 or size.y <= 0:
		return
	scale_factor = maxi(1, mini(size.x / min_view.x, size.y / min_view.y))
	view_size = Vector2i(
		clampi(size.x / scale_factor, min_view.x, max_view.x),
		clampi(size.y / scale_factor, min_view.y, max_view.y))
	win.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	win.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	win.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_INTEGER
	win.content_scale_size = view_size


## Safe area in game pixels (notch, Dynamic Island, home indicator). Use for HUD and touch
## controls; the world itself renders edge to edge.
func safe_rect() -> Rect2i:
	var win: Window = get_tree().root
	var safe: Rect2i = DisplayServer.get_display_safe_area()
	var screen: Vector2i = DisplayServer.screen_get_size()
	if safe.size == Vector2i.ZERO or screen == Vector2i.ZERO:
		return Rect2i(Vector2i.ZERO, view_size)
	# Offset of the rendered view inside the window (letterbox, if any).
	var drawn := view_size * scale_factor
	var origin := (win.size - drawn) / 2
	var pos := (safe.position - origin) / scale_factor
	var end := (safe.end - origin) / scale_factor
	pos = pos.clamp(Vector2i.ZERO, view_size)
	end = end.clamp(Vector2i.ZERO, view_size)
	return Rect2i(pos, end - pos)
