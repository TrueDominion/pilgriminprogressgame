extends Node
## Stage 3's optional detour (design/levels/stage3.md): take Mr Worldly Wiseman's smooth
## road, walk into the falling rocks at Mount Sinai, and check that Evangelist sends
## Christian back to waystation A. Pass: he reached the detour, the rocks fell near him,
## and he ended back at checkpoint A with the rebuke heard. Run headless:
##   godot --headless --fixed-fps 60 --path game res://tests/detour_test.tscn

const TILE := 16.0
const MAX_FRAMES := 60 * 90


func _ready() -> void:
	Audio.enabled = false
	Settings.assist = true
	Dialogue.autoplay_choice = 0          # the smooth road
	SaveSystem.current_slot = 2
	SaveSystem.erase(2)
	SaveSystem.data = SaveSystem.empty_state()
	Level.requested_id = "stage3"
	var level: Level = load("res://scenes/stage.tscn").instantiate()
	add_child(level)
	await get_tree().process_frame
	var p := level.player
	var reached_detour := false
	var returned := false
	for frame in MAX_FRAMES:
		await get_tree().physics_frame
		Input.action_press("move_right")
		var tx := p.global_position.x / TILE
		if tx > 320.0:
			reached_detour = true
		if SaveSystem.data["flags"].get("stage3_evangelist_rebuke", false) and not level._busy and tx < 40.0:
			returned = true
			break
	Input.action_release("move_right")
	var ok := reached_detour and returned and level.hazards.hits > 0
	print("Detour: reached Sinai %s, rock hits %d, sent back to waystation A %s" % [reached_detour, level.hazards.hits, returned])
	print("RESULT: %s" % ("PASS" if ok else "FAIL"))
	SaveSystem.erase(2)
	get_tree().quit(0 if ok else 1)
