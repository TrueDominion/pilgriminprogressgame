extends Node2D
## Greybox movement test range (issue #2). Proves the reach limits in gdd.md 4.3:
## steps 2 / 3 / 5 tiles and gaps 3 / 5 / 8 tiles (burdened / free / double jump). Press B (or Y, or the B touch button) to
## toggle the burden anywhere. Layout is data in LAYOUT; units are tiles.

const TILE := 16
const PLAYER_SCENE := preload("res://scenes/player.tscn")

# [x_start, x_end, height]: solid ground blocks. Height counts tiles above the base line.
const LAYOUT := [
	[0, 20, 0], [20, 26, 1], [26, 34, 3], [34, 40, 3],
	[42, 50, 3],                                   # 2-tile gap before it (burdened critical path)
	[53, 60, 3],                                   # 3-tile gap before it (burdened max, needs timing)
	[60, 74, 3],                                   # mud pool on top, x 62..72
	[74, 80, 6], [80, 86, 9], [86, 92, 14],        # 3-step single, 3-step, 5-step double
	[96, 104, 14],                                 # 4-tile gap (free single, critical path)
	[109, 117, 14],                                # 5-tile gap (free single max)
	[125, 145, 14],                                # 8-tile gap (double jump max)
]
const MUD := [[62, 72, 3]]
const LABELS := [
	[20, 1, "RANGE_STEP", 1], [26, 3, "RANGE_STEP", 2], [40, 3, "RANGE_GAP", 2], [50, 3, "RANGE_GAP", 3],
	[74, 6, "RANGE_STEP", 3], [80, 9, "RANGE_STEP", 3], [86, 14, "RANGE_STEP", 5],
	[92, 14, "RANGE_GAP", 4], [104, 14, "RANGE_GAP", 5], [117, 14, "RANGE_GAP", 8],
]
const CHECKPOINTS := [[4, 0], [36, 3], [56, 3], [76, 6], [98, 14], [111, 14]]
const FALL_LIMIT_TILES := 12   # below the base line

var player: Player
var _checkpoint := Vector2.ZERO
var _fading := false

@onready var _camera: Camera2D = $Camera
@onready var _hud: Label = %Stats
@onready var _help: Label = %Help
@onready var _fade: ColorRect = %Fade


func _ready() -> void:
	for b: Array in LAYOUT:
		_add_block(b[0], b[1], b[2])
	for mz: Array in MUD:
		_add_mud(mz[0], mz[1], mz[2])
	for l: Array in LABELS:
		_add_label(l[0], l[1], tr(l[2]) % l[3])
	_add_label(62, 3, tr("RANGE_MUD"))
	player = PLAYER_SCENE.instantiate()
	add_child(player)
	_checkpoint = _tile_pos(CHECKPOINTS[0][0], CHECKPOINTS[0][1])
	player.respawn_at(_checkpoint)
	player.failed.connect(func(_r: String) -> void: _respawn())
	_camera.limit_left = 0
	_camera.limit_right = 145 * TILE
	_camera.limit_bottom = 8 * TILE
	InputSetup.device_changed.connect(_update_help)
	_update_help(InputSetup.last_device)


func _tile_pos(tx: float, h: float) -> Vector2:
	return Vector2(tx * TILE + TILE / 2.0, -h * TILE)


func _add_block(x0: int, x1: int, h: int) -> void:
	var rect := Rect2(x0 * TILE, -h * TILE, (x1 - x0) * TILE, (h + 8) * TILE)
	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = rect.size
	shape.shape = rs
	shape.position = rect.get_center()
	body.add_child(shape)
	add_child(body)
	var vis := Polygon2D.new()
	vis.polygon = PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)])
	vis.color = Color("4a3020")
	add_child(vis)
	var top := Polygon2D.new()
	top.polygon = PackedVector2Array([rect.position, rect.position + Vector2(rect.size.x, 0), rect.position + Vector2(rect.size.x, 4), rect.position + Vector2(0, 4)])
	top.color = Color("6a8f4e")
	add_child(top)
	# tile grid marks, so step heights can be read on screen
	for tx in range(x0, x1):
		var mark := Polygon2D.new()
		var p := Vector2(tx * TILE, -h * TILE + 4)
		mark.polygon = PackedVector2Array([p, p + Vector2(1, 0), p + Vector2(1, 2), p + Vector2(0, 2)])
		mark.color = Color("36502c")
		add_child(mark)


func _add_mud(x0: int, x1: int, h: int) -> void:
	var area := Area2D.new()
	var shape := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2((x1 - x0) * TILE, 12)
	shape.shape = rs
	shape.position = Vector2((x0 + x1) * TILE / 2.0, -h * TILE - 4)
	area.add_child(shape)
	area.body_entered.connect(func(b: Node) -> void: if b is Player: b.enter_mud())
	area.body_exited.connect(func(b: Node) -> void: if b is Player: b.exit_mud())
	add_child(area)
	var vis := Polygon2D.new()
	var r := Rect2(x0 * TILE, -h * TILE, (x1 - x0) * TILE, 6)
	vis.polygon = PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])
	vis.color = Color("6b4a2e")
	add_child(vis)


func _add_label(tx: int, h: int, text: String) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 8)
	l.add_theme_color_override("font_color", Color("c9b48a"))
	l.position = Vector2(tx * TILE, -h * TILE - 40)
	add_child(l)


func _physics_process(_delta: float) -> void:
	if player == null:
		return
	for c: Array in CHECKPOINTS:
		var p := _tile_pos(c[0], c[1])
		if player.is_on_floor() and player.global_position.x >= p.x and p.x > _checkpoint.x and absf(player.global_position.y - p.y) < 2.0:
			_checkpoint = p
	if player.global_position.y > FALL_LIMIT_TILES * TILE and not _fading:
		_respawn()
	_camera.global_position = player.global_position.round() + Vector2(0, -32)
	_hud.text = "%s · %s" % [tr("RANGE_MODE_BURDENED") if player.burdened else tr("RANGE_MODE_FREE"),
		tr("RANGE_STATS") % [absf(player.velocity.x), player.stat_jump_height_px / TILE, player.stat_jump_length_px / TILE]]
	if player.sink_depth > 0.0:
		_hud.text += " · " + tr("RANGE_SINK") % [player.sink_depth, 30]


func _respawn() -> void:
	if _fading:
		return
	_fading = true
	player.frozen = true
	var t := create_tween()
	t.tween_property(_fade, "color:a", 1.0, 0.3)
	t.tween_callback(func() -> void: player.respawn_at(_checkpoint))
	t.tween_property(_fade, "color:a", 0.0, 0.3)
	t.tween_callback(func() -> void:
		player.frozen = false
		_fading = false)


func _update_help(device: String) -> void:
	_help.text = tr({"keys": "RANGE_HELP_KEYS", "pad": "RANGE_HELP_PAD", "touch": "RANGE_HELP_TOUCH"}[device])
