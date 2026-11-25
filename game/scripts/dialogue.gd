extends CanvasLayer
## Dialogue box and choices (autoload `Dialogue`). All text comes from translation keys
## (content/dialogue/*.csv via tools/sync_content.py), speakers from dialogue_speakers.json.
##   await Dialogue.say(["S1_HOME_01", "S1_HOME_02"])
##   var pick: int = await Dialogue.choose("S1_CHOICE_PROMPT", ["S1_CHOICE_STAY", "S1_CHOICE_GO"])
## Advance with Jump, Action, Enter or a tap. Holding advances quickly.

signal line_shown(key: String)

const SPEAKERS_PATH := "res://data/dialogue_speakers.json"
const SPEAKER_COLOURS := {
	"christian": Color("f0b94d"), "evangelist": Color("73aed0"), "obstinate": Color("e3765a"),
	"pliable": Color("f9d77e"), "family": Color("c9b48a"), "townsfolk": Color("c9b48a"),
	"narrator": Color("a8906a"), "sign": Color("a9c77a"), "ui": Color("f4ead5"), "help": Color("9cc98a"),
}
## Speaker names are translation keys SPEAKER_<ID> in data/strings.csv; a speaker without
## a key (narrator, ui) shows no name.

var active := false
## Test hook: when >= 0, choose() returns this option and say() advances by itself.
var autoplay_choice := -1
var _speakers := {}
var _panel: PanelContainer
var _name: Label
var _text: Label
var _arrow: Label
var _choices: VBoxContainer
var _advance := false
var _chars_per_second := 60.0


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(SPEAKERS_PATH))
	if raw is Dictionary:
		_speakers = raw
	_build_ui()
	_panel.visible = false


func _build_ui() -> void:
	_panel = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("f4ead5")
	sb.border_color = Color("241a38")
	sb.set_border_width_all(2)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	_panel.add_theme_stylebox_override("panel", sb)
	add_child(_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	_panel.add_child(box)
	_name = Label.new()
	_name.add_theme_font_size_override("font_size", 8)
	box.add_child(_name)
	_text = Label.new()
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.add_theme_font_size_override("font_size", 8)
	_text.add_theme_color_override("font_color", Color("241a38"))
	_text.custom_minimum_size = Vector2(0, 30)
	box.add_child(_text)
	_choices = VBoxContainer.new()
	_choices.add_theme_constant_override("separation", 2)
	box.add_child(_choices)
	_arrow = Label.new()
	_arrow.text = ">>"
	_arrow.add_theme_font_size_override("font_size", 8)
	_arrow.add_theme_color_override("font_color", Color("a8691e"))
	_arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	box.add_child(_arrow)


func _layout() -> void:
	var safe := Rect2(ScreenFit.safe_rect())
	var w := minf(safe.size.x - 16, 420.0)
	_panel.custom_minimum_size = Vector2(w, 0)
	_panel.size = Vector2(w, 0)
	_panel.position = Vector2(safe.position.x + (safe.size.x - w) / 2.0, safe.position.y + 8)


func _input(event: InputEvent) -> void:
	if not active:
		return
	var pressed: bool = event.is_action_pressed("jump") or event.is_action_pressed("action") \
		or (event is InputEventScreenTouch and event.pressed) \
		or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT)
	if pressed and _choices.get_child_count() == 0:
		_advance = true
		get_viewport().set_input_as_handled()


func _show_line(key: String) -> void:
	var who: String = _speakers.get(key, "narrator")
	var name_key := "SPEAKER_" + who.to_upper()
	_name.text = tr(name_key) if tr(name_key) != name_key else ""
	_name.visible = _name.text != ""
	_name.add_theme_color_override("font_color", SPEAKER_COLOURS.get(who, Color("241a38")).darkened(0.35))
	_text.text = tr(key)
	_text.visible_ratio = 0.0
	Audio.sfx("dialogue", -6.0, 0.05)
	line_shown.emit(key)


## Shows each line in turn; returns when the last one is dismissed.
func say(keys: Array) -> void:
	active = true
	_layout()
	_panel.visible = true
	for key: String in keys:
		_show_line(key)
		_advance = false
		var shown := 0.0
		var total := float(_text.text.length())
		while _text.visible_ratio < 1.0:
			await get_tree().process_frame
			var fast := Input.is_action_pressed("jump") or Input.is_action_pressed("action") or autoplay_choice >= 0
			shown += get_process_delta_time() * _chars_per_second * (4.0 if fast else 1.0)
			_text.visible_ratio = clampf(shown / maxf(total, 1.0), 0.0, 1.0)
			if _advance:
				_text.visible_ratio = 1.0
				_advance = false
		_arrow.visible = true
		if autoplay_choice >= 0:
			_advance = true
		while not _advance:
			await get_tree().process_frame
		_advance = false
		_arrow.visible = false
	_panel.visible = false
	await get_tree().process_frame
	active = false


## Shows a prompt line and option buttons; returns the chosen index.
func choose(prompt_key: String, option_keys: Array) -> int:
	active = true
	_layout()
	_panel.visible = true
	_show_line(prompt_key)
	_text.visible_ratio = 1.0
	_arrow.visible = false
	if autoplay_choice >= 0:
		_panel.visible = false
		await get_tree().process_frame
		active = false
		return mini(autoplay_choice, option_keys.size() - 1)
	var picked := [-1]
	var buttons: Array[Button] = []
	for i in option_keys.size():
		var b := Button.new()
		b.text = tr(option_keys[i])
		b.add_theme_font_size_override("font_size", 8)
		b.custom_minimum_size = Vector2(0, 24)
		b.focus_mode = Control.FOCUS_ALL
		b.pressed.connect(func() -> void:
			Audio.sfx("menu_select")
			picked[0] = i)
		b.focus_entered.connect(func() -> void: Audio.sfx("menu_move", -6.0))
		_choices.add_child(b)
		buttons.append(b)
	buttons[0].grab_focus()
	while picked[0] == -1:
		await get_tree().process_frame
	for b in buttons:
		b.queue_free()
	await get_tree().process_frame
	_panel.visible = false
	active = false
	return picked[0]
