class_name TouchControls
extends Control
## On-screen controls: a virtual stick on the left, buttons on the right.
## Feeds the same input actions as keyboard and gamepad, so gameplay code never
## knows which method is in use. Layout sits inside the safe area (ScreenFit).
## Shown on touch devices, and on desktop after the first touch or click on the screen.

const STICK_RADIUS := 26.0
const KNOB_RADIUS := 10.0
const DEADZONE := 0.3

var opacity := 0.6
var buttons := [
	{"action": "jump", "label": "TOUCH_JUMP", "radius": 20.0},
	{"action": "action", "label": "TOUCH_ACT", "radius": 16.0},
	{"action": "debug_toggle_burden", "label": "TOUCH_BURDEN", "radius": 12.0},
]
var _stick_finger := -1
var _stick_origin := Vector2.ZERO
var _stick_vec := Vector2.ZERO
var _button_fingers := {}   # finger index -> action


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = DisplayServer.is_touchscreen_available()
	InputSetup.device_changed.connect(func(d: String) -> void: visible = d == "touch" or DisplayServer.is_touchscreen_available())
	get_viewport().size_changed.connect(queue_redraw)


func _layout() -> Dictionary:
	var safe := Rect2(ScreenFit.safe_rect())
	var stick_c := Vector2(safe.position.x + 44, safe.end.y - 44)
	var right := safe.end.x
	var bottom := safe.end.y
	var pos := {
		"jump": Vector2(right - 34, bottom - 36),
		"action": Vector2(right - 78, bottom - 26),
		"debug_toggle_burden": Vector2(right - 66, bottom - 70),
	}
	return {"stick": stick_c, "buttons": pos}


func _input(event: InputEvent) -> void:
	if not (event is InputEventScreenTouch or event is InputEventScreenDrag):
		return
	visible = true
	var p: Vector2 = get_global_transform_with_canvas().affine_inverse() * event.position
	var lay := _layout()
	if event is InputEventScreenTouch:
		if event.pressed:
			for b: Dictionary in buttons:
				if p.distance_to(lay["buttons"][b["action"]]) <= b["radius"] + 8.0:
					_button_fingers[event.index] = b["action"]
					Input.action_press(b["action"])
					queue_redraw()
					return
			if p.x < get_viewport_rect().size.x * 0.5 and _stick_finger == -1:
				_stick_finger = event.index
				_stick_origin = p
				_update_stick(p)
		else:
			if _button_fingers.has(event.index):
				Input.action_release(_button_fingers[event.index])
				_button_fingers.erase(event.index)
			elif event.index == _stick_finger:
				_stick_finger = -1
				_update_stick(_stick_origin)
		queue_redraw()
	elif event is InputEventScreenDrag and event.index == _stick_finger:
		_update_stick(p)
		queue_redraw()


func _update_stick(p: Vector2) -> void:
	_stick_vec = ((p - _stick_origin) / STICK_RADIUS).limit_length(1.0)
	_set_axis("move_left", "move_right", _stick_vec.x)
	_set_axis("move_up", "move_down", _stick_vec.y)


func _set_axis(neg: String, pos: String, v: float) -> void:
	Input.action_release(neg)
	Input.action_release(pos)
	if v <= -DEADZONE:
		Input.action_press(neg, absf(v))
	elif v >= DEADZONE:
		Input.action_press(pos, v)


func _draw() -> void:
	var lay := _layout()
	var ink := Color("241a38", opacity)
	var parch := Color("f4ead5", opacity)
	var gold := Color("f0b94d", opacity)
	var stick_c: Vector2 = _stick_origin if _stick_finger != -1 else lay["stick"]
	draw_circle(stick_c, STICK_RADIUS, Color(ink, opacity * 0.6))
	draw_arc(stick_c, STICK_RADIUS, 0, TAU, 32, parch, 1.0)
	draw_circle(stick_c + _stick_vec * STICK_RADIUS, KNOB_RADIUS, parch)
	var font := get_theme_default_font()
	for b: Dictionary in buttons:
		var c: Vector2 = lay["buttons"][b["action"]]
		var down: bool = b["action"] in _button_fingers.values()
		draw_circle(c, b["radius"], gold if down else Color(ink, opacity * 0.6))
		draw_arc(c, b["radius"], 0, TAU, 32, parch, 1.0)
		var label := tr(b["label"])
		var size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_CENTER, -1, 8)
		draw_string(font, c + Vector2(-size.x / 2.0, 3), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, ink if down else parch)
