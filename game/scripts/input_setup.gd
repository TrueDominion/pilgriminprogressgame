extends Node
## Registers the input map from res://data/input.json at startup (autoload `InputSetup`).
## Keyboard bindings use physical key codes so they work on any keyboard layout.

const PATH := "res://data/input.json"

const JOY_BUTTONS := {
	"a": JOY_BUTTON_A, "b": JOY_BUTTON_B, "x": JOY_BUTTON_X, "y": JOY_BUTTON_Y,
	"start": JOY_BUTTON_START, "back": JOY_BUTTON_BACK,
	"left_shoulder": JOY_BUTTON_LEFT_SHOULDER, "right_shoulder": JOY_BUTTON_RIGHT_SHOULDER,
	"dpad_up": JOY_BUTTON_DPAD_UP, "dpad_down": JOY_BUTTON_DPAD_DOWN,
	"dpad_left": JOY_BUTTON_DPAD_LEFT, "dpad_right": JOY_BUTTON_DPAD_RIGHT,
}
const JOY_AXES := {"left_x": JOY_AXIS_LEFT_X, "left_y": JOY_AXIS_LEFT_Y}

## Which input method the player used last: "keys", "pad" or "touch". UI prompts follow it.
var last_device := "keys"
signal device_changed(device: String)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if not data is Dictionary:
		push_error("input.json is missing or invalid")
		return
	var deadzone: float = data.get("deadzone", 0.25)
	for action: String in data["actions"]:
		var spec: Dictionary = data["actions"][action]
		if not InputMap.has_action(action):
			InputMap.add_action(action, deadzone)
		for key_name: String in spec.get("keys", []):
			var ev := InputEventKey.new()
			ev.physical_keycode = OS.find_keycode_from_string(key_name)
			InputMap.action_add_event(action, ev)
		for b: String in spec.get("joy_buttons", []):
			var jb := InputEventJoypadButton.new()
			jb.button_index = JOY_BUTTONS[b]
			InputMap.action_add_event(action, jb)
		for ax: Array in spec.get("joy_axes", []):
			var jm := InputEventJoypadMotion.new()
			jm.axis = JOY_AXES[ax[0]]
			jm.axis_value = float(ax[1])
			InputMap.action_add_event(action, jm)


func _input(event: InputEvent) -> void:
	var device := last_device
	if event is InputEventKey:
		device = "keys"
	elif event is InputEventJoypadButton or (event is InputEventJoypadMotion and absf(event.axis_value) > 0.5):
		device = "pad"
	elif event is InputEventScreenTouch:
		device = "touch"
	if device != last_device:
		last_device = device
		device_changed.emit(device)
