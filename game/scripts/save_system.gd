extends Node
## Three local save slots (autoload `SaveSystem`). Files live in user:// (the app's own
## sandbox on iOS, browser storage on the web). Nothing leaves the device.
## A slot stores: stage, checkpoint id, collected light and scrolls (by id), flags, playtime.

const SLOTS := 3
const VERSION := 1

var current_slot := 0
var data := {}          # the active slot's state


func _path(slot: int) -> String:
	return "user://slot_%d.json" % slot


func empty_state() -> Dictionary:
	return {"version": VERSION, "stage": "stage1", "checkpoint": "", "light": [], "scrolls": [],
		"flags": {}, "playtime_s": 0.0, "updated": ""}


func peek(slot: int) -> Dictionary:
	## Returns the saved state for a slot, or an empty dictionary if the slot is unused.
	if not FileAccess.file_exists(_path(slot)):
		return {}
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(_path(slot)))
	return raw if raw is Dictionary else {}


func select(slot: int) -> void:
	current_slot = slot
	data = peek(slot)
	if data.is_empty():
		data = empty_state()


func most_recent_slot() -> int:
	var best := -1
	var best_time := ""
	for s in SLOTS:
		var d := peek(s)
		if not d.is_empty() and str(d.get("updated", "")) > best_time:
			best_time = str(d.get("updated", ""))
			best = s
	return best


func save() -> void:
	data["updated"] = Time.get_datetime_string_from_system(true)
	var f := FileAccess.open(_path(current_slot), FileAccess.WRITE)
	if f == null:
		push_error("Could not save slot %d" % current_slot)
		return
	f.store_string(JSON.stringify(data))


func erase(slot: int) -> void:
	if FileAccess.file_exists(_path(slot)):
		DirAccess.remove_absolute(_path(slot))
