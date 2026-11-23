extends Node
## Build metadata, available everywhere as the `Build` autoload.
## CI writes the commit hash into res://data/build.json at export time.

var version: String = ProjectSettings.get_setting("application/config/version", "0.0.0")
var commit: String = "dev"


func _ready() -> void:
	var path := "res://data/build.json"
	if FileAccess.file_exists(path):
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if data is Dictionary and data.has("commit"):
			commit = str(data["commit"])


func label() -> String:
	return "v%s (%s)" % [version, commit]
