extends Node2D
## Automated reach test for the player controller (issue #2).
## Builds a step or a gap, runs the real Player at full speed, presses Jump at a sweep
## of take-off points, and records whether any attempt lands on top. Expected results
## are the measured maximums in gdd.md 4.3 (they include hitbox width and coyote time). Run headless:
##   godot --headless --fixed-fps 60 --path game res://tests/movement_test.tscn
## Exit code 0 = all cases as expected.

const TILE := 16
const PLAYER_SCENE := preload("res://scenes/player.tscn")

# [label, burdened, kind, tiles, use_double, expect_pass]
const CASES := [
	["burdened step 2", true, "step", 2, false, true],
	["burdened step 3", true, "step", 3, false, false],
	["burdened gap 3 (max)", true, "gap", 3, false, true],
	["burdened gap 4", true, "gap", 4, false, false],
	["free step 3", false, "step", 3, false, true],
	["free step 4 (single)", false, "step", 4, false, false],
	["free step 5 (double)", false, "step", 5, true, true],
	["free step 6 (double)", false, "step", 6, true, false],
	["free gap 5 (max single)", false, "gap", 5, false, true],
	["free gap 6 (single)", false, "gap", 6, false, false],
	["free gap 8 (max double)", false, "gap", 8, true, true],
	["free gap 9 (double)", false, "gap", 9, true, false],
]

var _world: Node2D


func _ready() -> void:
	Audio.enabled = false
	var failures := 0
	for c: Array in CASES:
		var ok := await _run_case(c[1], c[2], c[3], c[4])
		var as_expected: bool = ok == c[5]
		if not as_expected:
			failures += 1
		print("%-24s %s  (expected %s)%s" % [c[0], "clears" if ok else "blocked", "clears" if c[5] else "blocked", "" if as_expected else "  <-- MISMATCH"])
	print("RESULT: %s" % ("PASS" if failures == 0 else "FAIL (%d)" % failures))
	get_tree().quit(0 if failures == 0 else 1)


func _block(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = rect.size
	shape.shape = rs
	shape.position = rect.get_center()
	body.add_child(shape)
	_world.add_child(body)


func _run_case(burdened: bool, kind: String, tiles: int, use_double: bool) -> bool:
	# sweep take-off offsets: positive = earlier (before the edge or face), in px
	var offsets := range(-6, 60, 3) if kind == "step" else range(-6, 10, 2)
	for off: int in offsets:
		if await _attempt(burdened, kind, tiles, use_double, off):
			return true
	return false


func _attempt(burdened: bool, kind: String, tiles: int, use_double: bool, offset: int) -> bool:
	if _world:
		_world.queue_free()
		await get_tree().physics_frame
	_world = Node2D.new()
	add_child(_world)
	var edge_x := 40.0 * TILE            # step face or gap start
	var target_top := 0.0
	var target_x0 := edge_x
	if kind == "step":
		_block(Rect2(0, 0, edge_x, 64))
		_block(Rect2(edge_x, -tiles * TILE, 20 * TILE, tiles * TILE + 64))
		target_top = -tiles * TILE
	else:
		_block(Rect2(0, 0, edge_x, 64))
		target_x0 = edge_x + tiles * TILE
		_block(Rect2(target_x0, 0, 20 * TILE, 64))
	var p: Player = PLAYER_SCENE.instantiate()
	p.burdened = burdened
	_world.add_child(p)
	p.respawn_at(Vector2(4 * TILE, 0))
	await get_tree().physics_frame
	var half_w := p.m.hitbox.x / 2.0
	var trigger_x := edge_x - half_w - offset
	Input.action_press("move_right")
	var jumped := false
	var doubled := false
	var result := false
	for i in 600:
		await get_tree().physics_frame
		if not jumped and p.global_position.x >= trigger_x:
			Input.action_press("jump")
			jumped = true
		elif jumped and not doubled and use_double and p.velocity.y > -20.0 and not p.is_on_floor():
			Input.action_release("jump")
			await get_tree().physics_frame
			Input.action_press("jump")
			doubled = true
		if jumped and p.is_on_floor() and p.global_position.x > target_x0 + half_w:
			result = absf(p.global_position.y - target_top) < 1.0
			break
		if p.global_position.y > 200.0:
			break
	Input.action_release("move_right")
	Input.action_release("jump")
	return result
