extends CanvasLayer
## Pause overlay (wireframes: design/ui/wireframes.html, Pause). Opened by the pause
## action (Esc / P / Start) or the on-screen pause button. Resume is first and focused;
## "Return to title" asks once, inline. Volume sliders are live and saved on close.

signal closed

var _panel: PanelContainer
var _dim: ColorRect
var _resume: Button
var _quit: Button
var _confirming := false
var _pause_button: Button


func _ready() -> void:
	layer = 15
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	_dim.visible = false


func _build() -> void:
	# on-screen pause button (touch and mouse), top right inside the safe area
	_pause_button = Button.new()
	_pause_button.text = "II"
	_pause_button.custom_minimum_size = Vector2(26, 24)
	_pause_button.add_theme_font_size_override("font_size", 8)
	_pause_button.focus_mode = Control.FOCUS_NONE
	_pause_button.pressed.connect(open)
	add_child(_pause_button)
	_dim = ColorRect.new()
	_dim.color = Color(0.06, 0.04, 0.1, 0.72)
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.add_child(center)
	_panel = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("f4ead5")
	sb.border_color = Color("241a38")
	sb.set_border_width_all(2)
	sb.set_content_margin_all(10)
	_panel.add_theme_stylebox_override("panel", sb)
	center.add_child(_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	box.custom_minimum_size = Vector2(180, 0)
	_panel.add_child(box)
	var title := Label.new()
	title.text = tr("PAUSE_TITLE")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color("241a38"))
	box.add_child(title)
	_resume = _button(tr("PAUSE_RESUME"), 16)
	_resume.pressed.connect(close)
	box.add_child(_resume)
	box.add_child(_slider(tr("PAUSE_MUSIC"), Settings.music, func(v: float) -> void:
		Settings.music = v
		Settings.apply()))
	box.add_child(_slider(tr("PAUSE_EFFECTS"), Settings.effects, func(v: float) -> void:
		Settings.effects = v
		Settings.apply()
		Audio.sfx("light", -4.0)))
	_quit = _button(tr("PAUSE_QUIT"), 8)
	_quit.flat = true   # ember text straight on parchment reads better than on a grey button
	for state in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color"]:
		_quit.add_theme_color_override(state, Color("9c3a2b"))
	_quit.pressed.connect(_on_quit)
	box.add_child(_quit)


func _button(text: String, size: int) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 24 if size > 8 else 20)
	b.add_theme_font_size_override("font_size", size)
	b.focus_entered.connect(func() -> void: Audio.sfx("menu_move", -6.0))
	return b


func _slider(label: String, value: float, on_change: Callable) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var l := Label.new()
	l.text = label
	l.custom_minimum_size = Vector2(56, 0)
	l.add_theme_font_size_override("font_size", 8)
	l.add_theme_color_override("font_color", Color("241a38"))
	row.add_child(l)
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.1
	s.value = value
	s.custom_minimum_size = Vector2(110, 20)
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.value_changed.connect(on_change)
	row.add_child(s)
	return row


func _process(_delta: float) -> void:
	var safe := Rect2(ScreenFit.safe_rect())
	_pause_button.position = Vector2(safe.end.x - 30, safe.position.y + 6)
	_pause_button.visible = not get_tree().paused and not Dialogue.active


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if get_tree().paused:
			close()
		elif not Dialogue.active:
			open()
		get_viewport().set_input_as_handled()


func open() -> void:
	if get_tree().paused:
		return
	get_tree().paused = true
	_confirming = false
	_quit.text = tr("PAUSE_QUIT")
	_dim.visible = true
	Audio.sfx("menu_select", -4.0)
	_resume.grab_focus()


func close() -> void:
	get_tree().paused = false
	_dim.visible = false
	Settings.save()
	closed.emit()


func _on_quit() -> void:
	if not _confirming:
		# ask once, inline: progress since the last waystation is lost
		_confirming = true
		_quit.text = tr("PAUSE_QUIT_CONFIRM")
		return
	Settings.save()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/title.tscn")
