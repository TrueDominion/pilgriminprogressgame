extends Node
## Bot playthrough of one stage with the burden on (issue #5). Holds right, jumps when
## blocked or at a ledge, reads signs that reveal hidden steps, lets dialogue auto-advance
## and chooses "go". Passes when the exit is reached. Run headless:
##   godot --headless --fixed-fps 60 --path game res://tests/stage_playthrough.tscn -- --level=stage2
## (no --level means stage1)

const MAX_FRAMES := 60 * 240

var _level: Level
var _level_id := "stage1"
var _last_read := {}   # sign id -> frame it was last read


func _ready() -> void:
	Audio.enabled = false
	SaveSystem.current_slot = 2
	SaveSystem.erase(2)
	SaveSystem.data = SaveSystem.empty_state()
	Dialogue.autoplay_choice = 1
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
		if not focus.is_empty() and focus["kind"] == "read" and focus["data"].has("reveals") and not p.frozen:
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


func _finish(ok: bool, frames: int, max_x: float, respawns: int) -> void:
	Input.action_release("move_right")
	Input.action_release("jump")
	Input.action_release("action")
	print("%s bot: %s in %.0f s of game time, furthest x %.0f tiles, respawns %d, light %d" % [
		_level_id, "REACHED EXIT" if ok else "DID NOT FINISH", frames / 60.0, max_x / 16.0, respawns, _level.light_count])
	print("RESULT: %s" % ("PASS" if ok else "FAIL"))
	SaveSystem.erase(2)
	get_tree().quit(0 if ok else 1)
