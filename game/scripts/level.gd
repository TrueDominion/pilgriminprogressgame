class_name Level
extends Node2D
## Builds and runs a stage from res://data/levels/<id>.json (greybox geometry, NPCs,
## signs, checkpoints, Scrolls, Light, exit). All text is translation keys.
## Saving: SaveSystem holds the active slot; checkpoints and pickups write to it.

const TILE := 16
const PLAYER_SCENE := preload("res://scenes/player.tscn")
const LEVEL_DIR := "res://data/levels/"

@export var level_id := "stage1"
## Set before changing to the stage scene to load another stage (title, stage exits).
static var requested_id := ""

var def: Dictionary
var player: Player
var light_count := 0
var _checkpoint_pos := Vector2.ZERO
var _checkpoint_id := ""
var _fading := false
var _busy := false               # a scripted scene is running
var _hidden := {}                # id -> Array[Node2D]
var _interactables: Array = []   # [{pos, kind, data}]
var _focus: Dictionary = {}      # the interactable in range, if any
var _follower: Node2D
var _playtime_start := 0.0
var _gloom: CanvasModulate
var hazards: Hazards
var _lamps: HopeLamps

@onready var _camera: Camera2D = $Camera
@onready var _world: Node2D = $World
@onready var _hud_stats: Label = %HudStats
@onready var _prompt: Label = %Prompt
@onready var _fade: ColorRect = %Fade
@onready var _card: Label = %StageCard


func _ready() -> void:
	if requested_id != "":
		level_id = requested_id
	def = JSON.parse_string(FileAccess.get_file_as_string(LEVEL_DIR + level_id + ".json"))
	if SaveSystem.data.is_empty():
		SaveSystem.select(0)
	_build()
	_spawn_player()
	_update_hud()
	_playtime_start = Time.get_ticks_msec() / 1000.0
	Audio.music(str(def.get("music", level_id)))
	if def.has("intro") and str(SaveSystem.data.get("checkpoint", "")) == "" and not SaveSystem.data.get("flags", {}).get(level_id + "_intro", false):
		_run_intro()
	else:
		_show_card()


# ------------------------------------------------------------------ building

func _tile_pos(tx: float, h: float) -> Vector2:
	return Vector2(tx * TILE, -h * TILE)


func _rect_poly(r: Rect2, colour: Color, parent: Node = _world) -> Polygon2D:
	var p := Polygon2D.new()
	p.polygon = PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])
	p.color = colour
	parent.add_child(p)
	return p


func _tex(name: String) -> Texture2D:
	# "env" lets a greybox stage borrow another stage's art until its own exists
	var path := "res://assets/env/%s/%s.png" % [def.get("env", level_id), name]
	return load(path) if ResourceLoader.exists(path) else null


func _tex_poly(r: Rect2, tex: Texture2D, parent: Node = _world, fallback := Color("4a3020")) -> Polygon2D:
	var p := _rect_poly(r, Color.WHITE if tex else fallback, parent)
	if tex:
		p.texture = tex
		p.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		p.uv = p.polygon   # world-aligned, so neighbouring blocks continue the same texture
	return p


func _sprite(name: String, bottom_centre: Vector2, parent: Node = _world) -> Sprite2D:
	var tex := _tex(name)
	if tex == null:
		return null
	var spr := Sprite2D.new()
	spr.texture = tex
	spr.centered = false
	spr.position = (bottom_centre - Vector2(tex.get_width() / 2.0, tex.get_height())).round()
	parent.add_child(spr)
	return spr


func _ground_h(x0: float, x1: float) -> float:
	## Height of the plain ground under a prop block (for placing crates and carts on it).
	var best := 0.0
	for s: Array in def["solids"]:
		if s.size() < 4 and s[0] < x1 and s[1] > x0:
			best = maxf(best, s[2])
	return best


func _solid(x0: float, x1: float, h: float, kind := "") -> void:
	var rect := Rect2(x0 * TILE, -h * TILE, (x1 - x0) * TILE, (h + 12) * TILE)
	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = rect.size
	shape.shape = rs
	shape.position = rect.get_center()
	body.add_child(shape)
	_world.add_child(body)
	match kind:
		"invisible":
			return
		"wall":
			_tex_poly(rect, _tex("tex_stone_wall"))
		"crates":
			var base := _ground_h(x0, x1)
			var r := Rect2(x0 * TILE, -h * TILE, (x1 - x0) * TILE, (h - base) * TILE)
			_rect_poly(r, Color("241a38"))
			_tex_poly(r.grow(-1), _tex("tex_planks"))
			_rect_poly(Rect2(r.position + Vector2(1, 1), Vector2(r.size.x - 2, 1)), Color("c9b48a"))
		"cart":
			var base := _ground_h(x0, x1)
			_sprite("prop_cart", Vector2((x0 + x1) * TILE / 2.0, -base * TILE))
		"hedge", "cover":
			# hedges (narrow way) and rocks (cover from arrows); drawn plainly until their art exists
			var base := _ground_h(x0, x1)
			var r := Rect2(x0 * TILE, -h * TILE, (x1 - x0) * TILE, (h - base) * TILE)
			var fill := Color("3f5a34") if kind == "hedge" else Color("6c677d")
			_rect_poly(r, Color("241a38"))
			_rect_poly(r.grow(-1), fill)
			_rect_poly(Rect2(r.position + Vector2(1, 1), Vector2(r.size.x - 2, 2)), fill.lightened(0.25))
		_:
			var field: bool = x0 >= float(def.get("field_from", 99999))
			_tex_poly(Rect2(rect.position + Vector2(0, 12), rect.size - Vector2(0, 12)), _tex("tex_field" if field else "tex_earth"))
			_tex_poly(Rect2(rect.position, Vector2(rect.size.x, 16)), _tex("tex_grass_top" if field else "tex_street_top"), _world, Color("6c677d"))


func _platform(x0: float, x1: float, h: float, parent: Node = _world, colour := Color("8a5a34")) -> Node2D:
	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2((x1 - x0) * TILE, 4)
	shape.shape = rs
	shape.one_way_collision = true
	shape.position = Vector2((x0 + x1) * TILE / 2.0, -h * TILE + 2)
	body.add_child(shape)
	parent.add_child(body)
	_rect_poly(Rect2(x0 * TILE, -h * TILE, (x1 - x0) * TILE, 4), colour, body)
	return body


func _label(text: String, pos: Vector2, colour := Color("c9b48a")) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 8)
	l.add_theme_color_override("font_color", colour)
	l.position = pos
	_world.add_child(l)
	return l


func _area(pos: Vector2, size: Vector2, on_enter: Callable) -> Area2D:
	var a := Area2D.new()
	var s := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = size
	s.shape = rs
	a.add_child(s)
	a.position = pos
	if on_enter.is_valid():
		a.body_entered.connect(func(b: Node) -> void: if b is Player: on_enter.call())
	_world.add_child(a)
	return a


func _build() -> void:
	_build_backdrop()
	for d: Dictionary in def.get("decor", []):
		match str(d["kind"]):
			"house":
				var r := Rect2(d["x"] * TILE, -d["top"] * TILE, (d["x1"] - d["x"]) * TILE, (d["top"] - d["h"]) * TILE)
				var wall := _tex_poly(r, _tex("tex_timber"), _world, Color("352a52"))
				wall.modulate = Color(0.75, 0.7, 0.85)
			_:
				_sprite("prop_" + str(d["kind"]), _tile_pos(d["x"], d["h"]))
	for pr: Dictionary in def.get("props", []):
		_sprite("prop_" + str(pr["prop"]), _tile_pos(pr["x"], pr["h"]))
	# plain ground first, then crates and carts drawn on top of it
	for s: Array in def["solids"]:
		if s.size() < 4 or s[3] == "wall":
			_solid(s[0], s[1], s[2], s[3] if s.size() > 3 else "")
	for s: Array in def["solids"]:
		if s.size() > 3 and s[3] != "wall":
			_solid(s[0], s[1], s[2], s[3])
	for p: Array in def.get("platforms", []):
		_platform(p[0], p[1], p[2])
	for m: Array in def.get("mud", []):
		_add_mud(m[0], m[1], m[2])
	for m: Array in def.get("deep_mud", []):
		_mud_surface(m[0], m[1], -0.4, Color("2a1d16"))
	if def.has("gloom"):
		_gloom = CanvasModulate.new()
		add_child(_gloom)
	for hd: Dictionary in def.get("hidden", []):
		var nodes: Array = []
		for p: Array in hd["platforms"]:
			var n := _platform(p[0], p[1], p[2], _world, Color("f0b94d"))
			n.process_mode = Node.PROCESS_MODE_DISABLED
			n.visible = false
			nodes.append(n)
		_hidden[hd["id"]] = nodes
	var saved_light: Array = SaveSystem.data.get("light", [])
	var saved_scrolls: Array = SaveSystem.data.get("scrolls", [])
	var flags: Dictionary = SaveSystem.data.get("flags", {})
	# Light motes along parabolic arcs
	for arc: Array in def.get("light_arcs", []):
		var n: int = arc[3]
		for i in n:
			# id from the arc's position, not its list index, so inserting a section does not
			# change which motes an existing save remembers
			var id := "%s_l%d_%d_%d" % [level_id, int(arc[0]), int(arc[2]), i]
			if id in saved_light:
				light_count += 1
				continue
			var t := (i + 0.5) / float(n)
			var x: float = lerpf(arc[0], arc[1], t)
			var lift := 1.2 + 1.2 * sin(t * PI)
			_add_light(id, _tile_pos(x, arc[2] + lift))
	for s: Dictionary in def.get("scrolls", []):
		if s["id"] in saved_scrolls:
			continue
		if s.has("requires_flag") and not flags.get(s["requires_flag"], false):
			continue
		_add_scroll(s["id"], _tile_pos(s["x"] + 0.5, s["h"] + 1))
	for c: Dictionary in def.get("checkpoints", []):
		_add_checkpoint(c)
	for npc: Dictionary in def.get("npcs", []):
		_add_npc(npc, flags)
	if _follower and flags.get(level_id + "_obstinate", false):
		_follower.set_meta("following", true)
	for sg: Dictionary in def.get("signs", []):
		_add_sign(sg)
	for ev: Dictionary in def.get("events", []):
		_add_event(ev, flags)
	if def.has("rocks") or def.has("arrows"):
		hazards = Hazards.new()
		_world.add_child(hazards)
		hazards.setup(self)
	var ex: Dictionary = def["exit"]
	_rect_poly(Rect2(ex["x"] * TILE, -ex["h"] * TILE - 48, 6, 48), Color("f0b94d"))
	if ex.get("knock", false):
		# a gate: the stage ends when Christian knocks (Action), not by walking in
		_interactables.append({"pos": _tile_pos(ex["x"] - 0.5, ex["h"]), "kind": "knock", "data": ex})
	else:
		_area(_tile_pos(ex["x"], ex["h"]) + Vector2(0, -24), Vector2(16, 48), _on_exit)
	var b: Array = def["bounds"]
	_camera.limit_left = int(b[0] * TILE)
	_camera.limit_right = int(b[1] * TILE)
	_camera.limit_bottom = 6 * TILE


var _town_layers: Array[Parallax2D] = []
var _field_layers: Array[Parallax2D] = []


func _layer(name: String, scroll: Vector2, bottom_y: float) -> Parallax2D:
	var tex := _tex("layer_" + name)
	var px := Parallax2D.new()
	px.scroll_scale = scroll
	add_child(px)
	move_child(px, 0)
	if tex == null:
		return px
	px.repeat_size = Vector2(tex.get_width(), 0)
	px.repeat_times = 4
	var spr := Sprite2D.new()
	spr.texture = tex
	spr.centered = false
	spr.position = Vector2(0, bottom_y - tex.get_height())
	px.add_child(spr)
	return px


func _build_backdrop() -> void:
	# Parallax: sky, distant city, street houses, near walls (back to front). Layers are
	# mirrored copies, so they repeat without a seam. The town layers fade out past the gate.
	var sky := CanvasLayer.new()
	sky.layer = -10
	add_child(sky)
	var fill := ColorRect.new()
	fill.set_anchors_preset(Control.PRESET_FULL_RECT)
	fill.color = Color("1d1530")
	sky.add_child(fill)
	# added back to front with move_child(0), so add the nearest first. A stage can move
	# each layer's bottom edge and tint it: "backdrop": {"near": [bottom_y, brightness], ...}
	var bd: Dictionary = def.get("backdrop", {})
	var near := _layer("near", Vector2(0.75, 1.0), _bd_y(bd, "near", 6))
	_town_layers.append(near)
	_town_layers.append(_layer("mid", Vector2(0.45, 1.0), _bd_y(bd, "mid", 2)))
	_field_layers.append(_layer("fields", Vector2(0.45, 1.0), _bd_y(bd, "fields", 4)))
	var far := _layer("far", Vector2(0.2, 0.7), _bd_y(bd, "far", -60))
	for pair in [["near", near], ["far", far]]:
		if bd.has(pair[0]) and (bd[pair[0]] as Array).size() > 1:
			var v: float = bd[pair[0]][1]
			(pair[1] as Parallax2D).modulate = Color(v, v, v * 1.05)   # town fade sets only alpha
	var light := Parallax2D.new()
	light.scroll_scale = Vector2(0.05, 0.5)
	add_child(light)
	move_child(light, 0)
	var glow := Polygon2D.new()
	glow.polygon = PackedVector2Array([Vector2(0, -4), Vector2(4, 0), Vector2(0, 4), Vector2(-4, 0)])
	glow.color = Color("fff2c2")
	glow.position = Vector2(520, -120)
	light.add_child(glow)
	_layer("sky", Vector2(0.05, 0.5), _bd_y(bd, "sky", -40))


func _bd_y(bd: Dictionary, name: String, fallback: float) -> float:
	return float(bd[name][0]) if bd.has(name) else fallback


func _update_town_fade() -> void:
	var gate_x := float(def.get("field_from", 99999)) * TILE
	var t := clampf((_camera.global_position.x - (gate_x - 400.0)) / 400.0, 0.0, 1.0)
	for l in _town_layers:
		l.modulate.a = 1.0 - t
	for l in _field_layers:
		l.modulate.a = t


func _add_light(id: String, pos: Vector2) -> void:
	var holder := Node2D.new()
	holder.position = pos
	_world.add_child(holder)
	var gem := Polygon2D.new()
	gem.polygon = PackedVector2Array([Vector2(0, -3), Vector2(3, 0), Vector2(0, 3), Vector2(-3, 0)])
	gem.color = Color("f0b94d")
	holder.add_child(gem)
	var a := _area(pos, Vector2(10, 10), func() -> void:
		if not is_instance_valid(holder):
			return
		holder.queue_free()
		light_count += 1
		Audio.sfx("light", -4.0, 0.06)
		SaveSystem.data["light"].append(id)
		_update_hud())
	holder.tree_exited.connect(func() -> void: if is_instance_valid(a): a.queue_free())


func _add_scroll(id: String, pos: Vector2) -> void:
	var holder := Node2D.new()
	holder.position = pos
	_world.add_child(holder)
	_rect_poly(Rect2(-4, -5, 8, 10), Color("f4ead5"), holder)
	_rect_poly(Rect2(-5, -5, 10, 2), Color("a8691e"), holder)
	_rect_poly(Rect2(-5, 3, 10, 2), Color("a8691e"), holder)
	var a := _area(pos, Vector2(14, 14), func() -> void:
		if not is_instance_valid(holder):
			return
		holder.queue_free()
		SaveSystem.data["scrolls"].append(id)
		Audio.sfx("scroll")
		SaveSystem.save()
		_update_hud()
		_toast(tr("HUD_SCROLL_FOUND")))
	holder.tree_exited.connect(func() -> void: if is_instance_valid(a): a.queue_free())


func _add_checkpoint(c: Dictionary) -> void:
	var pos := _tile_pos(c["x"] + 0.5, c["h"])
	var lantern := _sprite("prop_lantern", pos)
	var lamp := Polygon2D.new()   # the glow, shown once the waystation is lit
	var pts := PackedVector2Array()
	for i in 12:
		pts.append(Vector2(cos(i * TAU / 12), sin(i * TAU / 12)) * 9)
	lamp.polygon = pts
	lamp.color = Color(0.94, 0.73, 0.3, 0.35)
	lamp.position = pos + Vector2(-2, -31)
	lamp.visible = false
	_world.add_child(lamp)
	if str(SaveSystem.data.get("checkpoint", "")) == c["id"]:
		lamp.visible = true
		if lantern:
			lantern.modulate = Color(1.25, 1.1, 0.8)
	_area(pos + Vector2(0, -16), Vector2(16, 32), func() -> void:
		if _checkpoint_id == c["id"]:
			return
		_checkpoint_id = c["id"]
		_checkpoint_pos = pos
		lamp.visible = true
		if lantern:
			lantern.modulate = Color(1.25, 1.1, 0.8)
		SaveSystem.data["checkpoint"] = c["id"]
		Audio.sfx("checkpoint")
		_save_progress()
		_toast(tr("CHECKPOINT")))
	if lantern:
		lantern.name = "Checkpoint_" + str(c["id"])


func _add_npc(npc: Dictionary, flags: Dictionary) -> void:
	var pos := _tile_pos(npc["x"] + 0.5, npc["h"])
	var body := Node2D.new()
	body.position = pos
	body.name = str(npc["id"])
	_world.add_child(body)
	var sprite_path: String = npc.get("sprite", "res://assets/sprites/npc/%s.png" % npc["id"])
	if ResourceLoader.exists(sprite_path):
		var spr := Sprite2D.new()
		spr.texture = load(sprite_path)
		spr.centered = false
		# every NPC turns to face Christian, who arrives from the left
		spr.flip_h = str(npc.get("faces", "left")) == "right"
		spr.position = Vector2(-spr.texture.get_width() / 2.0, -spr.texture.get_height())
		spr.name = "Sprite"
		spr.set_meta("faces", str(npc.get("faces", "left")))
		body.add_child(spr)
		# gentle idle: a 1 px bob, offset per character so they do not move in step
		var t := create_tween().set_loops()
		t.tween_interval(0.6 + fmod(float(npc["x"]) * 0.37, 0.8))
		t.tween_property(spr, "position:y", spr.position.y + 1, 0.0)
		t.tween_interval(0.9)
		t.tween_property(spr, "position:y", spr.position.y, 0.0)
	else:
		var c := Color(str(npc["colour"]))
		_rect_poly(Rect2(-7, -44, 14, 44), Color("241a38"), body)
		_rect_poly(Rect2(-6, -43, 12, 42), c, body)
		_rect_poly(Rect2(-4, -42, 8, 8), Color("e3d3b0"), body)
	var name_key := "NPC_" + str(npc["id"]).to_upper()
	var tag := Label.new()
	tag.text = tr(name_key) if tr(name_key) != name_key else ""
	tag.add_theme_font_size_override("font_size", 8)
	tag.add_theme_color_override("font_color", Color("c9b48a"))
	tag.position = Vector2(-20, -60)
	body.add_child(tag)
	if npc.get("follows", false):
		_follower = body
		if npc.get("following", false) and not flags.get("%s_%s_left" % [level_id, npc["id"]], false):
			body.set_meta("following", true)
		elif flags.get("%s_%s_left" % [level_id, npc["id"]], false):
			body.visible = false
	if npc.has("appears_on") and not flags.get("%s_%s" % [level_id, npc["appears_on"]], false):
		body.visible = false
	if npc.has("lines") and npc.has("trigger_x"):
		var flag := "%s_%s" % [level_id, npc["id"]]
		if flags.get(flag, false):
			if npc.get("follows", false):
				body.set_meta("following", true)
			return
		_area(_tile_pos(npc["trigger_x"], npc["h"]) + Vector2(0, -48), Vector2(16, 128), func() -> void:
			if SaveSystem.data["flags"].get(flag, false) or _busy:
				return
			SaveSystem.data["flags"][flag] = true
			_play_lines(npc["lines"])
			if npc["id"] == "obstinate":
				_follower.set_meta("following", true))


func _add_sign(sg: Dictionary) -> void:
	var pos := _tile_pos(sg["x"] + 0.5, sg["h"])
	if _sprite("prop_signpost", pos) == null:
		_rect_poly(Rect2(pos.x - 1, pos.y - 20, 2, 20), Color("85704f"))
		_rect_poly(Rect2(pos.x - 8, pos.y - 26, 16, 9), Color("c9b48a"))
	_interactables.append({"pos": pos, "kind": "read", "data": sg})



func _add_mud(x0: float, x1: float, h: float) -> void:
	## Sinking mud on top of ground of height h (gdd.md 4.4): the Area tells the player.
	var area := _area(Vector2((x0 + x1) * TILE / 2.0, -h * TILE - 4), Vector2((x1 - x0) * TILE, 12), Callable())
	area.body_entered.connect(func(b: Node) -> void:
		if b is Player:
			b.enter_mud())
	area.body_exited.connect(func(b: Node) -> void:
		if b is Player:
			b.exit_mud())
	_mud_surface(x0, x1, h, Color("4a3320"))


func _mud_surface(x0: float, x1: float, h: float, colour: Color) -> void:
	## Shallow mud is a dark band over the ground top; deep mire (h < 0) fills the pit.
	var top := -h * TILE - 3
	var depth := 12.0 * TILE if h < 0 else 9.0
	var tex := _tex("tex_water" if h < 0 else "tex_mud")
	if tex:
		_tex_poly(Rect2(x0 * TILE, top, (x1 - x0) * TILE, depth), tex, _world, colour)
		_rect_poly(Rect2(x0 * TILE, top, (x1 - x0) * TILE, 1), colour.lightened(0.3))
		return
	_rect_poly(Rect2(x0 * TILE, top, (x1 - x0) * TILE, depth), colour)
	_rect_poly(Rect2(x0 * TILE, top, (x1 - x0) * TILE, 1), colour.lightened(0.3))
	# a few bubbles so it reads as mire, not a shadow
	for i in int((x1 - x0) / 3.0):
		var bx := (x0 + 1.0 + i * 3.0 + fmod(i * 1.7, 1.5)) * TILE
		_rect_poly(Rect2(bx, top + 3 + (i % 2) * 2, 2, 2), colour.lightened(0.18))


func _add_event(ev: Dictionary, flags: Dictionary) -> void:
	## A one-time scripted moment, triggered by walking past tile x.
	var flag := "%s_%s" % [level_id, ev["id"]]
	if flags.get(flag, false):
		return
	_area(_tile_pos(ev["x"], ev.get("h", 0)) + Vector2(0, -48), Vector2(16, 160), func() -> void:
		if SaveSystem.data["flags"].get(flag, false) or _busy:
			return
		SaveSystem.data["flags"][flag] = true
		_run_event(ev))


func _run_event(ev: Dictionary) -> void:
	_busy = true
	player.no_fail = true   # Christian is frozen in place; standing in mud must not fail him
	match str(ev.get("action", "")):
		"rescue":
			# Christian sinks whatever the player does; a helper appears and pulls him out
			player.no_fail = true
			await get_tree().create_timer(float(ev.get("sink_s", 2.2))).timeout
			var helper := _world.get_node_or_null(str(ev["helper"])) as Node2D
			if helper:
				helper.visible = true
	await Dialogue.say(ev.get("lines", []))
	if ev.has("choice"):
		# a fork in the road: each option may send Christian somewhere ("goto": [[x, h] or null])
		var ch: Dictionary = ev["choice"]
		var pick: int = await Dialogue.choose(ch["prompt"], ch["options"])
		var dest: Variant = ch["goto"][pick]
		if dest is Array:
			await _teleport(_tile_pos(dest[0], dest[1]))
	match str(ev.get("action", "")):
		"follower_leaves":
			if _follower:
				_follower.set_meta("following", false)
				SaveSystem.data["flags"]["%s_%s_left" % [level_id, _follower.name]] = true
				var spr := _follower.get_node_or_null("Sprite") as Sprite2D
				if spr:
					spr.flip_h = spr.get_meta("faces", "left") == "right"
				var t := create_tween()
				t.tween_property(_follower, "position:x", _follower.position.x - 220.0, 2.4)
				t.parallel().tween_property(_follower, "modulate:a", 0.0, 2.4)
				t.tween_callback(func() -> void: _follower.visible = false)
		"return":
			# turned back: to the last waystation
			await _teleport(_checkpoint_pos)
		"rescue":
			var to: Array = ev["to"]
			var t := create_tween()
			t.tween_property(_fade, "color:a", 1.0, 0.4)
			await t.finished
			player.no_fail = false
			Audio.sfx("mud_pull", -2.0)
			player.respawn_at(_tile_pos(to[0], to[1]))
			_camera.global_position = player.global_position + Vector2(0, -40)
			_camera.reset_smoothing()
			t = create_tween()
			t.tween_property(_fade, "color:a", 0.0, 0.4)
	# Scrolls that wait for this moment (for example, behind where a companion turned back)
	var flags: Dictionary = SaveSystem.data["flags"]
	for sc: Dictionary in def.get("scrolls", []):
		if sc.get("requires_flag", "") == "%s_%s" % [level_id, ev["id"]] and not sc["id"] in SaveSystem.data.get("scrolls", []):
			_add_scroll(sc["id"], _tile_pos(sc["x"] + 0.5, sc["h"] + 1))
	if ev.has("after_lines"):
		await Dialogue.say(ev["after_lines"])
	player.no_fail = false
	_busy = false
	_save_progress()


func _teleport(pos: Vector2) -> void:
	var t := create_tween()
	t.tween_property(_fade, "color:a", 1.0, 0.4)
	await t.finished
	player.respawn_at(pos)
	_camera.global_position = player.global_position + Vector2(0, -40)
	_camera.reset_smoothing()
	t = create_tween()
	t.tween_property(_fade, "color:a", 0.0, 0.4)

# ------------------------------------------------------------------ play

func _spawn_player() -> void:
	player = PLAYER_SCENE.instantiate()
	player.burdened = true
	_world.add_child(player)
	var sp: Array = def["spawn"]
	_checkpoint_pos = _tile_pos(sp[0], sp[1])
	var saved_cp := str(SaveSystem.data.get("checkpoint", ""))
	for c: Dictionary in def.get("checkpoints", []):
		if c["id"] == saved_cp:
			_checkpoint_pos = _tile_pos(c["x"] + 0.5, c["h"])
			_checkpoint_id = saved_cp
	player.respawn_at(_checkpoint_pos)
	player.failed.connect(func(_r: String) -> void: _respawn())
	_lamps = HopeLamps.new()
	_lamps.player = player
	$HUD.add_child(_lamps)
	_camera.global_position = player.global_position + Vector2(0, -40)
	_camera.reset_smoothing()


func _physics_process(delta: float) -> void:
	if player == null:
		return
	player.frozen = _busy or Dialogue.active or _fading
	if player.global_position.y > def.get("fall_limit", 10) * TILE and not _fading:
		_respawn()
	_camera.global_position = (player.global_position + Vector2(0, -40)).round()
	for r: Array in def.get("camera_regions", []):
		# separate areas (an optional detour) keep the camera inside their own walls
		var tx := player.global_position.x / TILE
		if tx >= r[0] and tx <= r[1]:
			_camera.limit_left = int(r[0] * TILE)
			_camera.limit_right = int(r[1] * TILE)
	_update_follower(delta)
	if def.has("surface"):
		player.surface = str(def["surface"])
	else:
		player.surface = "grass" if player.global_position.x >= float(def.get("field_from", 99999)) * TILE else "stone"
	_update_town_fade()
	_update_gloom()
	_update_focus()
	if not _focus.is_empty() and not player.frozen and Input.is_action_just_pressed("action"):
		_interact(_focus)


func _update_gloom() -> void:
	## Darkens the world through a stretch of the stage (def "gloom": [x0, x1, strength]).
	if _gloom == null:
		return
	var g: Array = def["gloom"]
	var x := player.global_position.x / TILE
	var ramp := 12.0
	var t := clampf(minf((x - g[0]) / ramp, (g[1] - x) / ramp), 0.0, 1.0)
	_gloom.color = Color.WHITE.lerp(Color(0.55, 0.55, 0.68), t * float(g[2]))


func _update_follower(delta: float) -> void:
	if _follower == null or not _follower.get_meta("following", false):
		return
	var target := player.global_position + Vector2(-22 * player.facing, 0)
	var before := _follower.global_position.x
	_follower.global_position.x = move_toward(_follower.global_position.x, target.x, 140.0 * delta)
	var spr := _follower.get_node_or_null("Sprite") as Sprite2D
	if spr and absf(_follower.global_position.x - before) > 0.1:
		var moving_right := _follower.global_position.x > before
		var drawn_right: bool = spr.get_meta("faces", "left") == "right"
		spr.flip_h = moving_right != drawn_right
	if player.is_on_floor():
		_follower.global_position.y = move_toward(_follower.global_position.y, target.y, 200.0 * delta)


func _update_focus() -> void:
	_focus = {}
	for it: Dictionary in _interactables:
		if player.global_position.distance_to(it["pos"]) < 22.0:
			_focus = it
			break
	_prompt.visible = not _focus.is_empty() and not Dialogue.active
	if _prompt.visible:
		var key: String = {"read": "HINT_READ", "knock": "HINT_KNOCK"}.get(_focus["kind"], "HINT_TALK")
		var btn: String = {"keys": "E", "pad": "X", "touch": tr("TOUCH_ACT")}[InputSetup.last_device]
		_prompt.text = "%s  [%s]" % [tr(key), btn]


func _interact(it: Dictionary) -> void:
	var sg: Dictionary = it["data"]
	if it["kind"] == "knock":
		_busy = true
		_interactables.erase(it)
		Audio.sfx("menu_select", 0.0, 0.0, 0.6)
		var helper := _world.get_node_or_null(str(sg.get("helper", ""))) as Node2D
		if helper:
			helper.visible = true
		await Dialogue.say(sg.get("knock_lines", []))
		_busy = false
		_on_exit()
		return
	if it["kind"] == "read":
		_busy = true
		Audio.sfx("book")
		await player.play_action("read")
		await Dialogue.say(sg["lines"])
		_busy = false
		if sg.has("reveals"):
			_reveal(sg["reveals"])


func _reveal(id: String) -> void:
	for n: Node2D in _hidden.get(id, []):
		n.visible = true
		n.process_mode = Node.PROCESS_MODE_INHERIT
	await get_tree().create_timer(float(def.get("reveal_seconds", 8))).timeout
	for n: Node2D in _hidden.get(id, []):
		var t := create_tween()
		t.tween_property(n, "modulate:a", 0.2, 0.15).set_trans(Tween.TRANS_LINEAR)
		t.tween_property(n, "modulate:a", 1.0, 0.15)
		t.set_loops(3)
	await get_tree().create_timer(0.9).timeout
	for n: Node2D in _hidden.get(id, []):
		n.visible = false
		n.process_mode = Node.PROCESS_MODE_DISABLED


func _play_lines(lines: Array) -> void:
	_busy = true
	await Dialogue.say(lines)
	_busy = false
	_save_progress()


func _run_intro() -> void:
	_busy = true
	await get_tree().create_timer(0.4).timeout
	await Dialogue.say(def["intro"])
	var ch: Dictionary = def.get("intro_choice", {})
	while not ch.is_empty():
		var pick: int = await Dialogue.choose(ch["prompt"], ch["options"])
		if pick == 1:
			break
		await Dialogue.say(ch["stay_lines"])
	SaveSystem.data["flags"][level_id + "_intro"] = true
	_save_progress()
	_busy = false
	_show_card()


func _on_exit() -> void:
	if _busy:
		return
	_busy = true
	await Dialogue.say(def["exit"]["lines"])
	SaveSystem.data["flags"][level_id + "_complete"] = true
	SaveSystem.data["checkpoint"] = ""
	_save_progress()
	var next := str(def.get("next", ""))
	if next != "":
		SaveSystem.data["stage"] = next
		SaveSystem.save()
	var t := create_tween()
	t.tween_property(_fade, "color:a", 1.0, 0.8)
	await t.finished
	if next != "":
		requested_id = next
		get_tree().change_scene_to_file("res://scenes/stage.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/title.tscn")


func _respawn() -> void:
	if _fading:
		return
	_fading = true
	Audio.sfx("respawn", -2.0)
	var t := create_tween()
	t.tween_property(_fade, "color:a", 1.0, 0.3)
	t.tween_callback(func() -> void: player.respawn_at(_checkpoint_pos))
	t.tween_property(_fade, "color:a", 0.0, 0.3)
	t.tween_callback(func() -> void: _fading = false)


func _save_progress() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	SaveSystem.data["playtime_s"] = float(SaveSystem.data.get("playtime_s", 0.0)) + now - _playtime_start
	_playtime_start = now
	SaveSystem.data["stage"] = level_id
	SaveSystem.save()


# ------------------------------------------------------------------ HUD

func _update_hud() -> void:
	var total_scrolls: int = def.get("scrolls", []).size()
	var got := 0
	for s: Dictionary in def.get("scrolls", []):
		if s["id"] in SaveSystem.data.get("scrolls", []):
			got += 1
	_hud_stats.text = "%s %d   %s %d/%d" % [tr("HUD_LIGHT"), light_count, tr("HUD_SCROLLS"), got, total_scrolls]


## Hope as small lamps under the stats, top left of the safe area (gdd.md 5).
class HopeLamps extends Control:
	var player: Player

	func _process(_d: float) -> void:
		var safe := Rect2(ScreenFit.safe_rect())
		position = Vector2(maxf(34.0, safe.position.x + 12.0), safe.position.y + 26.0)
		queue_redraw()

	func _draw() -> void:
		if player == null:
			return
		for i in player.max_hope:
			var lit := i < player.hope
			var c := Vector2(i * 12.0, 0)
			draw_rect(Rect2(c + Vector2(-3, -4), Vector2(7, 9)), Color("241a38"))
			draw_rect(Rect2(c + Vector2(-2, -3), Vector2(5, 7)), Color("f0b94d") if lit else Color("4a3f5c"))
			if lit:
				draw_rect(Rect2(c + Vector2(-1, -2), Vector2(2, 2)), Color("fff2c2"))


func _toast(text: String) -> void:
	_card.text = text
	_card.modulate.a = 1.0
	var t := create_tween()
	t.tween_interval(1.2)
	t.tween_property(_card, "modulate:a", 0.0, 0.5)


func _show_card() -> void:
	_toast(tr(def["title_key"]))
