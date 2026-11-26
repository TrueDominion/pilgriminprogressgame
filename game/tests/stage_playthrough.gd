extends Node
## Bot playthrough of one stage with the burden on (issue #5). Holds right, jumps when
## blocked or at a ledge (and jumps again in the air once free of the burden), reads signs that
## reveal hidden steps, takes and uses items, knocks at gates, lets dialogue
## auto-advance and takes the second option of every choice ("go", "the narrow way"). Passes when the exit is reached. Run headless:
##   godot --headless --fixed-fps 60 --path game res://tests/stage_playthrough.tscn -- --level=stage2
## (no --level means stage1)

const MAX_FRAMES := 60 * 240

var _level: Level
var _level_id := "stage1"
var _last_read := {}   # sign id -> frame it was last read
var _doubled := false


func _ready() -> void:
	Audio.enabled = false
	SaveSystem.current_slot = 2
	SaveSystem.erase(2)
	SaveSystem.data = SaveSystem.empty_state()
	Dialogue.autoplay_choice = 1
	# Pilgrim's Aid: hazards cost no Hope, so the bot always finishes; hits are still counted
	Settings.assist = true
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--level="):
			_level_id = arg.trim_prefix("--level=")
	Level.requested_id = _level_id
	_level = load("res://scenes/stage.tscn").instantiate()
	add_child(_level)
	await get_tree().process_frame
	var p: Player = _level.player
	var stuck := 0
	var last_x := 0.0
	var max_x := 0.0
	var respawns := 0
	var jump_cooldown := 0
	for frame in MAX_FRAMES:
		await get_tree().physics_frame
		if SaveSystem.data.get("flags", {}).get(_level_id + "_complete", false):
			_finish(true, frame, max_x, respawns)
			return
		if p == null or not is_instance_valid(p):
			break
		Input.action_press("move_right")
		Input.action_release("action")
		# read a sign that reveals hidden steps, again after a respawn if the steps have faded
		var focus: Dictionary = _level._focus
		# one press, then let go: a held button never counts as a fresh press
		if not focus.is_empty() and focus["kind"] in ["knock", "item"] and not p.frozen:
			var key: String = focus["kind"] + str(focus["data"].get("id", ""))
			if frame - int(_last_read.get(key, -100000)) > 60 * 4:
				_last_read[key] = frame
				Input.action_press("action")
		elif not focus.is_empty() and focus["kind"] == "read" and focus["data"].has("reveals") and not p.frozen:
			var sid: String = focus["data"]["id"]
			if frame - int(_last_read.get(sid, -100000)) > 60 * 10:
				_last_read[sid] = frame
				Input.action_press("action")
		max_x = maxf(max_x, p.global_position.x)
		if p.global_position.x < last_x - 32.0:
			respawns += 1
		jump_cooldown -= 1
		var blocked: bool = p.is_on_floor() and absf(p.velocity.x) < 5.0 and not p.frozen
		var ahead := _ground_ahead(p)
		if jump_cooldown <= 0 and p.is_on_floor() and not p.frozen and (blocked or not ahead):
			Input.action_press("jump")
			jump_cooldown = 20
		elif not p.burdened and not p.is_on_floor() and p.velocity.y > 0.0 and not _ground_below(p) and not _doubled:
			# free set: a second jump when falling with nothing underneath
			Input.action_release("jump")
			await get_tree().physics_frame
			Input.action_press("jump")
			_doubled = true
			jump_cooldown = 20
		if p.is_on_floor():
			_doubled = false
		elif jump_cooldown < 8:
			Input.action_release("jump")
		stuck = stuck + 1 if absf(p.global_position.x - last_x) < 0.1 and not p.frozen else 0
		last_x = p.global_position.x
		if stuck > 60 * 20:
			break
	_finish(false, MAX_FRAMES, max_x, respawns)


func _ground_ahead(p: Player) -> bool:
	var space := p.get_world_2d().direct_space_state
	var q := PhysicsRayQueryParameters2D.create(p.global_position + Vector2(10, -4), p.global_position + Vector2(10, 20))
	return not space.intersect_ray(q).is_empty()


func _ground_below(p: Player) -> bool:
	var space := p.get_world_2d().direct_space_state
	var q := PhysicsRayQueryParameters2D.create(p.global_position + Vector2(8 * p.facing, -2), p.global_position + Vector2(8 * p.facing, 120))
	return not space.intersect_ray(q).is_empty()


func _finish(ok: bool, frames: int, max_x: float, respawns: int) -> void:
	Input.action_release("move_right")
	Input.action_release("jump")
	Input.action_release("action")
	print("%s bot: %s in %.0f s of game time, furthest x %.0f tiles, respawns %d, light %d, hazard hits %d" % [
		_level_id, "REACHED EXIT" if ok else "DID NOT FINISH", frames / 60.0, max_x / 16.0, respawns, _level.light_count,
		_level.hazards.hits if _level.hazards else 0])
	var f: Dictionary = SaveSystem.data.get("flags", {})
	var notable := f.keys().filter(func(k: String) -> bool: return k == "burden_off" or k.contains("revealed") or k.begins_with("item_"))
	if not notable.is_empty():
		print("%s bot: flags %s" % [_level_id, ", ".join(notable)])
	print("RESULT: %s" % ("PASS" if ok else "FAIL"))
	SaveSystem.erase(2)
	get_tree().quit(0 if ok else 1)
