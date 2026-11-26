class_name Player
extends CharacterBody2D
## Christian. Movement is fully data-driven from res://data/movement.json (gdd.md section 4).
## The Burden switches between the "burdened" and "free" movement sets.
## Placeholder art is drawn in _draw until the sprite sets exist.

signal burden_changed(burdened: bool)
signal jumped(kind: String)            # "jump" or "double"
signal landed(fall_px: float, heavy: bool)
signal failed(reason: String)          # sank, fell, hope; the level handles the respawn
signal hurt_taken(hope: int)           # after a hit, with Hope left

const TILE := 16.0

@export var burdened := true:
	set(value):
		burdened = value
		if is_node_ready():
			_apply_set()
			burden_changed.emit(burdened)

var sets: Dictionary
var m: MovementData
var facing := 1

# timers and state
var _coyote := 0.0
var _buffer := 0.0
var _can_double := false
var _jump_held := false
var _air_peak_y := 0.0
var _was_on_floor := true
var _stagger := 0.0
var _mud_areas := 0
var sink_depth := 0.0            # px sunk into mud; drawn as an offset
var frozen := false              # cutscenes and fades
var no_fail := false             # scripted sinking (Help's rescue): stop short of failure
var max_hope := 3                # gdd.md 5: 3 lamps, 4 with the Helmet
var hope := 3
var _invuln := 0.0               # seconds of invulnerability after a hit
var no_jump := false             # gentle input lock: walking only (the approach to the Cross)

# last-jump stats for the test range readout
var stat_jump_start := Vector2.ZERO
var stat_jump_height_px := 0.0
var stat_jump_length_px := 0.0
var _in_jump := false

@onready var _shape: CollisionShape2D = $Shape
var _sprite: AnimatedSprite2D
var _sprite_sets := {}   # "burdened" / "free" -> SpriteFrames (empty until art exists)
var _one_shot := ""
var surface := "stone"   # set by the level: stone, grass (mud is detected here)
var _step_timer := 0.0      # a one-shot animation (land, read, interact, hurt) that must finish
var _bubble_timer := 0.0    # mud bubbles while sinking, rising in pitch with depth


func _ready() -> void:
	sets = MovementData.load_all()
	_sprite_sets["free"] = SpriteSheets.load_folder("res://assets/sprites/christian")
	_sprite_sets["burdened"] = SpriteSheets.load_folder("res://assets/sprites/christian-burden")
	_sprite = AnimatedSprite2D.new()
	_sprite.centered = true
	_sprite.animation_finished.connect(func() -> void: _one_shot = "")
	add_child(_sprite)
	_apply_set()


func _apply_set() -> void:
	m = sets["burdened" if burdened else "free"]
	var rect := RectangleShape2D.new()
	rect.size = m.hitbox
	_shape.shape = rect
	_shape.position = Vector2(0, -m.hitbox.y / 2.0)
	var frames: SpriteFrames = _sprite_sets.get("burdened" if burdened else "free")
	if _sprite and frames and frames.has_animation("walk"):
		_sprite.sprite_frames = frames
		_sprite.visible = true
	elif _sprite:
		_sprite.visible = false
	queue_redraw()


func _physics_process(delta: float) -> void:
	var shared: Dictionary = sets["shared"]
	var on_floor := is_on_floor()
	var in_mud := _mud_areas > 0 and on_floor

	# --- input
	var dir := 0.0
	var jump_pressed := false
	if not frozen:
		dir = Input.get_axis("move_left", "move_right")
		jump_pressed = Input.is_action_just_pressed("jump") and not no_jump
		if Input.is_action_just_pressed("debug_toggle_burden"):
			burdened = not burdened
	var jump_down := Input.is_action_pressed("jump") and not frozen
	if dir != 0.0:
		facing = signi(int(signf(dir)))

	# --- timers
	if _invuln > 0.0:
		_invuln = maxf(_invuln - delta, 0.0)
		if _sprite:
			# soft blink, never a red flash (gdd.md 5)
			_sprite.modulate.a = 0.45 if fmod(_invuln, 0.2) > 0.1 else 1.0
			if _invuln == 0.0:
				_sprite.modulate.a = 1.0
	_coyote = shared["coyote_time_s"] if on_floor else maxf(_coyote - delta, 0.0)
	_buffer = shared["jump_buffer_s"] if jump_pressed else maxf(_buffer - delta, 0.0)
	_stagger = maxf(_stagger - delta, 0.0)
	if on_floor:
		_can_double = m.double_jump

	# --- horizontal
	var speed := m.run_speed * (m.mud_move_multiplier if in_mud else 1.0)
	var target := 0.0 if _stagger > 0.0 else dir * speed
	var accel: float
	if on_floor:
		accel = m.ground_accel if target != 0.0 else m.ground_decel
	else:
		accel = m.air_accel
	velocity.x = move_toward(velocity.x, target, accel * delta)

	# --- mud
	if in_mud:
		if absf(velocity.x) < 10.0:
			sink_depth += m.mud_sink_speed * delta
			_bubble_timer -= delta
			if _bubble_timer <= 0.0:
				_bubble_timer = 0.7
				# louder and higher as he sinks: a warning that needs no reading
				Audio.sfx("mud_bubble", -6.0 + sink_depth * 0.1, 0.03, 0.9 + sink_depth / 40.0)
		else:
			sink_depth = maxf(sink_depth - 6.0 * delta, 0.0)
		if no_fail:
			sink_depth = minf(sink_depth, 26.0)
		elif sink_depth >= 30.0:
			sink_depth = 0.0
			failed.emit("sank")
			return
	elif on_floor:
		sink_depth = 0.0
	var can_jump_from_ground := sink_depth < 16.0

	# --- jumping
	if _buffer > 0.0 and _coyote > 0.0 and can_jump_from_ground and _stagger <= 0.0:
		_start_jump(m.jump_velocity(), "jump")
	elif jump_pressed and not on_floor and _coyote <= 0.0 and _can_double:
		_can_double = false
		_start_jump(m.double_jump_velocity(), "double")
	if _jump_held and not jump_down and velocity.y < 0.0:
		velocity.y *= m.jump_cut_multiplier
		_jump_held = false
	if velocity.y >= 0.0:
		_jump_held = false

	# --- gravity
	var g := m.rise_gravity if velocity.y < 0.0 else m.fall_gravity
	if not on_floor:
		velocity.y = minf(velocity.y + g * delta, m.max_fall_speed)

	move_and_slide()

	# --- landing bookkeeping
	var now_on_floor := is_on_floor()
	if not now_on_floor:
		_air_peak_y = minf(_air_peak_y, global_position.y)
		if _in_jump:
			stat_jump_height_px = maxf(stat_jump_height_px, stat_jump_start.y - global_position.y)
	elif not _was_on_floor:
		var fall := global_position.y - _air_peak_y
		var heavy := fall >= m.heavy_landing_fall_px
		if heavy:
			_stagger = m.heavy_landing_recovery_s
		if _in_jump:
			stat_jump_length_px = absf(global_position.x - stat_jump_start.x)
			_in_jump = false
		landed.emit(fall, heavy)
		if fall > 8.0:
			Audio.sfx("land_heavy" if heavy or burdened else "land", -2.0, 0.05)
		if _sprite.visible and _sprite.sprite_frames.has_animation("land") and fall > 8.0:
			_one_shot = "land"
			_sprite.speed_scale = 1.0
			_sprite.play("land")
	if now_on_floor:
		_air_peak_y = global_position.y
	_was_on_floor = now_on_floor
	if now_on_floor and absf(velocity.x) > 10.0 and not frozen:
		_step_timer -= delta
		if _step_timer <= 0.0:
			_step_timer = (0.42 if burdened else 0.3) * (1.4 if _mud_areas > 0 else 1.0)
			var step := "step_mud" if _mud_areas > 0 else ("step_grass" if surface == "grass" else "step_stone")
			Audio.sfx(step, -8.0, 0.1)
	else:
		_step_timer = 0.0
	_update_sprite(now_on_floor)
	queue_redraw()


func _update_sprite(on_floor: bool) -> void:
	if not _sprite.visible:
		return
	# Cells are anchored bottom-centre on the feet; every cell is 56 px tall.
	_sprite.flip_h = facing < 0
	_sprite.position = Vector2(0, -28 + sink_depth)
	if _one_shot != "":
		return
	var want: String
	var speed := 1.0
	if not on_floor:
		want = "jump" if velocity.y < 0.0 else "fall"
	elif absf(velocity.x) > 5.0:
		want = "wade" if _mud_areas > 0 and _sprite.sprite_frames.has_animation("wade") else "walk"
		speed = absf(velocity.x) / (m.run_speed * (m.mud_move_multiplier if want == "wade" else 1.0))
	else:
		want = "idle"
	_play(want, speed)


func _play(anim: String, speed := 1.0) -> void:
	var frames := _sprite.sprite_frames
	if not frames.has_animation(anim):
		# fall back to the first frame of the walk until the full set exists
		_sprite.animation = "walk"
		_sprite.frame = 0
		_sprite.pause()
		return
	_sprite.speed_scale = speed
	if _sprite.animation != anim or not _sprite.is_playing():
		# one-shot animations (jump, fall) hold their last frame once finished
		if _sprite.animation == anim and not frames.get_animation_loop(anim):
			return
		_sprite.play(anim)


## Plays a one-shot action animation (read, interact, hurt) and waits for it.
func play_action(anim: String) -> void:
	if not _sprite.visible or not _sprite.sprite_frames.has_animation(anim):
		return
	_one_shot = anim
	_sprite.speed_scale = 1.0
	_sprite.play(anim)
	await _sprite.animation_finished


func _start_jump(vy: float, kind: String) -> void:
	velocity.y = vy
	_buffer = 0.0
	_coyote = 0.0
	_jump_held = true
	if kind == "jump":
		stat_jump_start = global_position
		stat_jump_height_px = 0.0
		_in_jump = true
	jumped.emit(kind)
	if kind == "double":
		Audio.sfx("jump", 0.0, 0.08)
	else:
		Audio.sfx("jump_burdened" if burdened else "jump", 0.0, 0.05)


## Called by mud Area2D nodes.
func enter_mud() -> void:
	_mud_areas += 1
	if _mud_areas == 1:
		Audio.sfx("mud_squelch_a" if randf() < 0.5 else "mud_squelch_b", -6.0, 0.06)


func exit_mud() -> void:
	_mud_areas = maxi(_mud_areas - 1, 0)
	if _mud_areas == 0:
		sink_depth = 0.0


## A hazard hit: 1 Hope, 1 s of invulnerability, knockback away from the source.
## With Pilgrim's Aid on, hazards cost no Hope (the knockback and blink still show the hit).
func hurt(from_x: float) -> void:
	if _invuln > 0.0 or frozen:
		return
	_invuln = 1.0
	var away := signf(global_position.x - from_x)
	if away == 0.0:
		away = -float(facing)
	velocity = Vector2(away * 150.0, -140.0)
	_stagger = 0.25
	Audio.sfx("hurt", 0.0, 0.05)
	if _sprite and _sprite.visible and _sprite.sprite_frames.has_animation("hurt"):
		_one_shot = "hurt"
		_sprite.speed_scale = 1.0
		_sprite.play("hurt")
	if not Settings.assist:
		hope -= 1
	hurt_taken.emit(hope)
	if hope <= 0:
		failed.emit("hope")


func respawn_at(pos: Vector2) -> void:
	hope = max_hope
	_invuln = 0.0
	if _sprite:
		_sprite.modulate.a = 1.0
	global_position = pos
	velocity = Vector2.ZERO
	sink_depth = 0.0
	_stagger = 0.0
	_air_peak_y = pos.y
	_in_jump = false


func _draw() -> void:
	if _sprite and _sprite.visible:
		return
	# Placeholder figure on the palette: body, head, and the burden.
	var ink := Color("241a38")
	var cloth := Color("85704f") if burdened else Color("f4ead5")
	var skin := Color("e3d3b0")
	var y0 := sink_depth
	var h := m.hitbox.y if m else 30.0
	var w := 12.0
	var squash := 2.0 if _stagger > 0.0 else 0.0
	var body := Rect2(-w / 2.0, -h + y0 + squash, w, h - squash)
	draw_rect(body.grow(1), ink)
	draw_rect(body, cloth)
	draw_rect(Rect2(-4 + facing, -h + 1 + y0 + squash, 8, 8), skin)
	draw_rect(Rect2(1 + facing * 2, -h + 4 + y0 + squash, 1, 1), ink)
	if burdened:
		var sack := Rect2(-w / 2.0 - 8 if facing > 0 else w / 2.0 - 2, -h + 3 + y0 + squash, 10, 16)
		draw_rect(sack.grow(1), ink)
		draw_rect(sack, Color("6c677d"))
		draw_rect(Rect2(sack.position.x, sack.position.y + 7, sack.size.x, 1), Color("a8906a"))
