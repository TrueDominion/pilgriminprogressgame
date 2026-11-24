class_name SpriteSheets
extends RefCounted
## Builds SpriteFrames from sheets named by the pipeline convention:
## {asset}_{action}_f{count}_{w}x{h}_g{cols}x{rows}_fps{n}_{loop|once}.png
## Every sheet in a folder becomes one animation named after its action.

static func load_folder(dir_path: String) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return frames
	var re := RegEx.create_from_string("^(?<asset>[a-z0-9-]+)_(?<action>[a-z0-9-]+)_f(?<n>\\d+)_(?<w>\\d+)x(?<h>\\d+)_g(?<c>\\d+)x(?<r>\\d+)_fps(?<fps>\\d+)_(?<mode>loop|once)\\.png$")
	for file in dir.get_files():
		# exported builds list imported files with a .import or .remap suffix
		var name := file.trim_suffix(".import").trim_suffix(".remap")
		var m := re.search(name)
		if m == null or frames.has_animation(m.get_string("action")):
			continue
		var tex: Texture2D = load(dir_path.path_join(name))
		var action := m.get_string("action")
		var w := int(m.get_string("w"))
		var h := int(m.get_string("h"))
		var cols := int(m.get_string("c"))
		frames.add_animation(action)
		frames.set_animation_speed(action, float(m.get_string("fps")))
		frames.set_animation_loop(action, m.get_string("mode") == "loop")
		for i in int(m.get_string("n")):
			var at := AtlasTexture.new()
			at.atlas = tex
			at.region = Rect2((i % cols) * w, (i / cols) * h, w, h)
			frames.add_frame(action, at)
	return frames
