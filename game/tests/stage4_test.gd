extends Node
## Stage 4 checks (design/levels/stage4.md):
## 1. The dusty parlour cannot be crossed before the water is poured: a walker that jumps at
##    every wall but never uses an item stays left of the parlour wall.
## 2. The basement under the fire room cannot be left before the oil-pourer is found.
## Run headless: godot --headless --fixed-fps 60 --path game res://tests/stage4_test.tscn

const TILE := 16.0


func _ready() -> void:
	Audio.enabled = false
	Settings.assist = true
	Dialogue.autoplay_choice = 1
	SaveSystem.current_slot = 2
	SaveSystem.erase(2)
	SaveSystem.data = SaveSystem.empty_state()
	SaveSystem.data["flags"]["stage4_intro"] = true
	SaveSystem.data["flags"]["stage4_interpreter"] = true
	SaveSystem.data["flags"]["stage4_damsel"] = true
	SaveSystem.data["flags"]["stage4_oil"] = true          # pretend the pourer is not reached
	Level.requested_id = "stage4"
	var level: Level = load("res://scenes/stage.tscn").instantiate()
	add_child(level)
	await get_tree().process_frame
	var parlour_x := await _walk(level, 30.0, 8.0)
	var basement_x := await _walk(level, 78.0, 8.0, -4.0)
	var ok := parlour_x < 45.0 and basement_x < 92.0
	print("Stage 4 gates: parlour stopped at tile %.1f (wall at 45), basement stopped at tile %.1f (exit at 92)" % [parlour_x, basement_x])
	print("RESULT: %s" % ("PASS" if ok else "FAIL"))
	SaveSystem.erase(2)
	get_tree().quit(0 if ok else 1)


func _walk(level: Level, from_tile: float, seconds: float, h := 0.0) -> float:
	## Holds right and jumps every half second; never presses Action.
	level.player.respawn_at(Vector2(from_tile * TILE, -h * TILE))
	var max_x := 0.0
	for i in int(seconds * 60):
		await get_tree().physics_frame
		Input.action_press("move_right")
		if i % 30 == 0:
			Input.action_press("jump")
		elif i % 30 == 12:
			Input.action_release("jump")
		max_x = maxf(max_x, level.player.global_position.x / TILE)
	Input.action_release("move_right")
	Input.action_release("jump")
	return max_x
