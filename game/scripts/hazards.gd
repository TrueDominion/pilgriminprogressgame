class_name Hazards
extends Node2D
## Timed hazards for a stage, read from the level file (gdd.md 5, design/levels/stage3.md).
##   "rocks":  [{"x0", "x1", "h", "every", "warn"}]  a shadow grows under Christian for `warn`
##             seconds, then a rock falls on that spot. Active while he is between x0 and x1.
##   "arrows": [{"x0", "x1", "h", "every", "warn"}]  a glint (and a high chime) gives `warn`
##             seconds' notice, then a volley of arrows comes down from the upper right.
##             Any solid stops an arrow, so rocks and hedges are cover.
## Hits cost 1 Hope through Player.hurt (none with Pilgrim's Aid). Units are tiles and seconds.

const TILE := 16.0
const ARROW_SPEED := 260.0          # px/s; slow on purpose, the burdened jump is slow
const ARROW_OFFSETS := [-56.0, -24.0, 0.0, 24.0, 56.0]   # px around Christian

var level: Level
var _rock_t: Array[float] = []
var _arrow_t: Array[float] = []
var _arrows: Array[Node2D] = []
var _glint: Polygon2D
var hits := 0                       # for the bot test's report


func setup(lvl: Level) -> void:
	level = lvl
	for z: Dictionary in level.def.get("rocks", []):
		_rock_t.append(float(z["every"]))
	for z: Dictionary in level.def.get("arrows", []):
		_arrow_t.append(float(z["every"]))
	var hud := CanvasLayer.new()
	hud.layer = 5
	add_child(hud)
	_glint = Polygon2D.new()
	_glint.polygon = PackedVector2Array([Vector2(0, -7), Vector2(3, -2), Vector2(8, 0), Vector2(3, 2),
		Vector2(0, 7), Vector2(-3, 2), Vector2(-8, 0), Vector2(-3, -2)])
	_glint.color = Color("fff2c2")
	_glint.visible = false
	hud.add_child(_glint)


func _physics_process(delta: float) -> void:
	var p := level.player
	if p == null or p.frozen:
		return
	var tx := p.global_position.x / TILE
	var rocks: Array = level.def.get("rocks", [])
	for i in rocks.size():
		var z: Dictionary = rocks[i]
		if tx < z["x0"] or tx > z["x1"]:
			_rock_t[i] = float(z["every"])
			continue
		_rock_t[i] -= delta
		if _rock_t[i] <= 0.0:
			_rock_t[i] = float(z["every"])
			# aim where he will be, so standing still and walking on are both answered
			_drop_rock(p.global_position.x + p.velocity.x * float(z["warn"]) + randf_range(-8, 8),
				-float(z.get("h", 0)) * TILE, float(z["warn"]))
	var fields: Array = level.def.get("arrows", [])
	var warning := false
	for i in fields.size():
		var z: Dictionary = fields[i]
		if tx < z["x0"] or tx > z["x1"]:
			_arrow_t[i] = float(z["every"])
			continue
		var before := _arrow_t[i]
		_arrow_t[i] -= delta
		var warn := float(z["warn"])
		if before > warn and _arrow_t[i] <= warn:
			Audio.sfx("light", -4.0, 0.0, 1.8)   # the glint has a sound, so it is not sight-only
		if _arrow_t[i] <= warn:
			warning = true
		if _arrow_t[i] <= 0.0:
			_arrow_t[i] = float(z["every"])
			_volley(p.global_position.x, -float(z.get("h", 0)) * TILE)
	_glint.visible = warning and fmod(Time.get_ticks_msec() / 1000.0, 0.3) < 0.2
	if _glint.visible:
		var safe := Rect2(ScreenFit.safe_rect())
		_glint.position = Vector2(safe.end.x - 60, safe.position.y + 40)
	_move_arrows(delta)


# ------------------------------------------------------------------ rocks

func _drop_rock(x: float, ground_y: float, warn: float) -> void:
	var shadow := Polygon2D.new()
	var pts := PackedVector2Array()
	for k in 10:
		var a := TAU * k / 10.0
		pts.append(Vector2(cos(a) * 9.0, sin(a) * 2.5))
	shadow.polygon = pts
	shadow.color = Color(0.08, 0.05, 0.12, 0.55)
	shadow.position = Vector2(x, ground_y - 1)
	shadow.scale = Vector2(0.3, 0.3)
	level.get_node("World").add_child(shadow)
	var t := create_tween()
	t.tween_property(shadow, "scale", Vector2.ONE, warn)
	t.tween_callback(func() -> void: _rock_falls(x, ground_y, shadow))


func _rock_falls(x: float, ground_y: float, shadow: Polygon2D) -> void:
	var rock := Polygon2D.new()
	rock.polygon = PackedVector2Array([Vector2(-7, -12), Vector2(5, -14), Vector2(8, -4), Vector2(3, 0),
		Vector2(-6, 0), Vector2(-9, -6)])
	rock.color = Color("6c677d")
	rock.position = Vector2(x, ground_y - 240)
	level.get_node("World").add_child(rock)
	var t := create_tween()
	t.tween_property(rock, "position:y", ground_y, 0.22).set_ease(Tween.EASE_IN)
	t.tween_callback(func() -> void:
		var p := level.player
		if p and absf(p.global_position.x - x) < 14.0 and p.global_position.y > ground_y - 44.0:
			hits += 1
			p.hurt(x)
		Audio.sfx("land_heavy", -4.0, 0.1)
		shadow.queue_free())
	t.tween_property(rock, "modulate:a", 0.0, 0.6)
	t.tween_callback(rock.queue_free)


# ------------------------------------------------------------------ arrows

func _volley(px: float, ground_y: float) -> void:
	for o: float in ARROW_OFFSETS:
		var target := Vector2(px + o + randf_range(-6, 6), ground_y)
		var arrow := Node2D.new()
		var shaft := Polygon2D.new()
		shaft.polygon = PackedVector2Array([Vector2(-9, -0.5), Vector2(6, -0.5), Vector2(9, 0), Vector2(6, 0.5), Vector2(-9, 0.5)])
		shaft.color = Color("241a38")
		arrow.add_child(shaft)
		var dir := Vector2(-1, 1).normalized()
		arrow.position = target - dir * 300.0
		arrow.rotation = dir.angle()
		arrow.set_meta("dir", dir)
		level.get_node("World").add_child(arrow)
		_arrows.append(arrow)


func _move_arrows(delta: float) -> void:
	var space := get_world_2d().direct_space_state
	for arrow: Node2D in _arrows.duplicate():
		if not is_instance_valid(arrow):
			_arrows.erase(arrow)
			continue
		var dir: Vector2 = arrow.get_meta("dir")
		var from: Vector2 = arrow.position
		var to: Vector2 = from + dir * ARROW_SPEED * delta
		var q := PhysicsRayQueryParameters2D.create(arrow.get_parent().to_global(from), arrow.get_parent().to_global(to))
		var hit := space.intersect_ray(q)
		if hit.is_empty():
			arrow.position = to
			continue
		_arrows.erase(arrow)
		if hit["collider"] is Player:
			hits += 1
			(hit["collider"] as Player).hurt(arrow.global_position.x + 40.0)
			arrow.queue_free()
		else:
			# stuck in the ground or in cover; fades out
			arrow.global_position = hit["position"]
			var t := create_tween()
			t.tween_interval(0.8)
			t.tween_property(arrow, "modulate:a", 0.0, 0.4)
			t.tween_callback(arrow.queue_free)
