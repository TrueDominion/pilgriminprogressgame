extends Node
## Checks that rocks are real cover in Stage 3's arrow field (design/levels/stage3.md).
## Christian stands still for two volleys behind a rock, then for two in the open.
## Pass: no hits behind the rock, at least one hit in the open. Run headless:
##   godot --headless --fixed-fps 60 --path game res://tests/arrow_cover_test.tscn

const TILE := 16.0
const WAIT_FRAMES := 60 * 11   # two volleys (every 5 s) plus the first warning


func _ready() -> void:
	Audio.enabled = false
	Settings.assist = true          # count hits without failing
	SaveSystem.current_slot = 2
	SaveSystem.erase(2)
	SaveSystem.data = SaveSystem.empty_state()
	SaveSystem.data["flags"]["stage3_intro"] = true
	Level.requested_id = "stage3"
	var level: Level = load("res://scenes/stage.tscn").instantiate()
	add_child(level)
	await get_tree().process_frame
	var behind := await _stand(level, 138.6)   # just left of the rock at 140 to 142
	var open := await _stand(level, 146.5)     # between rocks
	print("Arrow cover: behind a rock %d hits, in the open %d hits" % [behind, open])
	var ok := behind == 0 and open > 0
	print("RESULT: %s" % ("PASS" if ok else "FAIL"))
	SaveSystem.erase(2)
	get_tree().quit(0 if ok else 1)


func _stand(level: Level, tile_x: float) -> int:
	level.player.respawn_at(Vector2(tile_x * TILE, 0))
	var before := level.hazards.hits
	for i in WAIT_FRAMES:
		await get_tree().physics_frame
	return level.hazards.hits - before
