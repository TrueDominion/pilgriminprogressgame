extends Control
## Title and save-slot screen (wireframes: design/ui/wireframes.html).
## Continue resumes the most recent slot; otherwise the slot list opens.
## Every control works with touch, gamepad (focus) and keyboard.

const STAGE_SCENE := "res://scenes/stage.tscn"
const RANGE_SCENE := "res://scenes/test_range.tscn"

@onready var _main: VBoxContainer = %Main
@onready var _slots: VBoxContainer = %Slots
@onready var _primary: Button = %Primary
@onready var _range: Button = %Range
@onready var _info: Label = %Info
var _hold := {}   # slot -> seconds held on erase


func _ready() -> void:
	Audio.music("title")
	get_viewport().gui_focus_changed.connect(func(_c: Control) -> void: Audio.sfx("menu_move", -6.0))
	%Name.text = tr("TITLE_NAME")
	%Sub.text = tr("TITLE_SUB")
	_info.text = Build.label()
	_range.text = tr("TITLE_TEST_RANGE")
	var recent := SaveSystem.most_recent_slot()
	_primary.text = tr("TITLE_CONTINUE") if recent >= 0 else tr("TITLE_BEGIN")
	_primary.pressed.connect(func() -> void:
		if recent >= 0:
			_start(recent)
		else:
			_show_slots())
	_range.pressed.connect(func() -> void: get_tree().change_scene_to_file(RANGE_SCENE))
	_slots.visible = false
	_primary.grab_focus.call_deferred()


func _show_slots() -> void:
	_main.visible = false
	_slots.visible = true
	for c in _slots.get_children():
		c.queue_free()
	var head := Label.new()
	head.text = tr("TITLE_CHOOSE")
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_theme_font_size_override("font_size", 16)
	_slots.add_child(head)
	var first: Button
	for slot in SaveSystem.SLOTS:
		var d := SaveSystem.peek(slot)
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 6)
		var b := Button.new()
		b.custom_minimum_size = Vector2(240, 28)
		b.add_theme_font_size_override("font_size", 8)
		if d.is_empty():
			b.text = "%s · %s" % [tr("TITLE_SLOT") % (slot + 1), tr("TITLE_EMPTY")]
		else:
			var stage := str(d.get("stage", "stage1"))
			var where := tr(stage.to_upper() + "_TITLE")
			if d.get("flags", {}).get(stage + "_complete", false):
				where = tr("TITLE_SLOT_DONE") % where
			b.text = "%s · %s" % [tr("TITLE_SLOT") % (slot + 1), tr("TITLE_SLOT_INFO") % [where, d.get("light", []).size(), d.get("scrolls", []).size()]]
		b.pressed.connect(func() -> void: _start(slot))
		row.add_child(b)
		if not d.is_empty():
			var e := Button.new()
			e.text = tr("TITLE_ERASE")
			e.add_theme_font_size_override("font_size", 8)
			e.custom_minimum_size = Vector2(80, 28)
			e.button_down.connect(func() -> void: _hold[slot] = 0.0)
			e.button_up.connect(func() -> void: _hold.erase(slot))
			e.set_meta("slot", slot)
			row.add_child(e)
		_slots.add_child(row)
		if first == null:
			first = b
	var back := Button.new()
	back.text = tr("TITLE_BACK")
	back.add_theme_font_size_override("font_size", 8)
	back.pressed.connect(func() -> void:
		_slots.visible = false
		_main.visible = true
		_primary.grab_focus())
	_slots.add_child(back)
	first.grab_focus.call_deferred()


func _process(delta: float) -> void:
	# Erase needs a 1.5 s hold so a child cannot wipe a game with one tap.
	for slot: int in _hold.keys():
		_hold[slot] += delta
		if _hold[slot] >= 1.5:
			_hold.erase(slot)
			SaveSystem.erase(slot)
			_show_slots()
			return


func _start(slot: int) -> void:
	Audio.sfx("menu_select")
	SaveSystem.select(slot)
	var stage := str(SaveSystem.data.get("stage", "stage1"))
	if SaveSystem.data.get("flags", {}).get(stage + "_complete", false):
		# The last stage built so far is finished: replay it from its start.
		SaveSystem.data["checkpoint"] = ""
		SaveSystem.data["flags"].erase(stage + "_complete")
	Level.requested_id = stage
	get_tree().change_scene_to_file(STAGE_SCENE)


func _unhandled_input(event: InputEvent) -> void:
	if _slots.visible and event.is_action_pressed("pause"):
		_slots.visible = false
		_main.visible = true
		_primary.grab_focus()
