class_name Player
extends CharacterBody2D
## Christian. Movement is fully data-driven from res://data/movement.json (gdd.md section 4).
## The Burden switches between the "burdened" and "free" movement sets.
## Placeholder art is drawn in _draw until the sprite sets exist.

signal burden_changed(burdened: bool)
signal jumped(kind: String)            # "jump" or "double"
signal landed(fall_px: float, heavy: bool)
signal failed(reason: String)          # sank, fell; the level handles the respawn

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

# last-jump stats for the test range readout
var stat_jump_start := Vector2.ZERO
var stat_jump_height_px := 0.0
var stat_jump_length_px := 0.0
var _in_jump := false

@onready var _shape: CollisionShape2D = $Shape
var _sprite: AnimatedSprite2D
var _sprite_sets := {}   # "burdened" / "free" -> SpriteFrames (empty until art exists)


func _ready() -> void:
	sets = MovementData.load_all()
	_sprite_sets["free"] = SpriteSheets.load_folder("res://assets/sprites/christian")
	_sprite = AnimatedSprite2D.new()
	_sprite.centered = false
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
		jump_pressed = Input.is_action_just_pressed("jump")
		if Input.is_action_just_pressed("debug_toggle_burden"):
			burdened = not burdened
	var jump_down := Input.is_action_pressed("jump") and not frozen
	if dir != 0.0:
		facing = signi(int(signf(dir)))

	# --- timers
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
		else:
			sink_depth = maxf(sink_depth - 6.0 * delta, 0.0)
		if sink_depth >= 30.0:
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
	if now_on_floor:
		_air_peak_y = global_position.y
	_was_on_floor = now_on_floor
	_update_sprite(now_on_floor)
	queue_redraw()


func _update_sprite(on_floor: bool) -> void:
	if not _sprite.visible:
		return
	# Cell is 40x56, anchored bottom-centre on the feet.
	_sprite.flip_h = facing < 0
	_sprite.position = Vector2(-20, -56 + sink_depth)
	if on_floor and absf(velocity.x) > 5.0:
		_sprite.speed_scale = absf(velocity.x) / m.run_speed
		if _sprite.animation != "walk" or not _sprite.is_playing():
			_sprite.play("walk")
	else:
		# until idle / jump sheets exist, hold the contact frame
		_sprite.animation = "walk"
		_sprite.frame = 0
		_sprite.pause()


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


## Called by mud Area2D nodes.
func enter_mud() -> void:
	_mud_areas += 1


func exit_mud() -> void:
	_mud_areas = maxi(_mud_areas - 1, 0)
	if _mud_areas == 0:
		sink_depth = 0.0


func respawn_at(pos: Vector2) -> void:
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
