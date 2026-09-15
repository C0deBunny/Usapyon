extends Node

## How the values persist. It knows the shape of the file and nothing about what
## the numbers mean — a new Usapyon comes from GameState.reset_to_new().
##
## Autoload, registered after GameState because _ready() writes into it.
##
## Writes are atomic: the new state goes to a .tmp, the current file is kept as
## .bak, and only then is the temp renamed over the real file. An Android kill
## mid-write therefore leaves either the old save or the new one, never half of
## one — and a file that will not parse falls back to the backup. "Your pet
## vanished" is the worst failure this game has.

## Bumped to 2 when cleanliness and happiness arrived. Fields were only added,
## never redefined, so a version-1 save still opens — load_game() reads its
## absent keys as a new Usapyon's starting value.
const VERSION: int = 2

## Debug and release never share a file, so a deliberately strange test state
## cannot contaminate real progression — see docs/conventions.md.
const DEBUG_BASE: String = "user://savegame_debug"
const RELEASE_BASE: String = "user://savegame"

var _main_path: String
var _backup_path: String
var _temp_path: String


func _ready() -> void:
	var base: String = DEBUG_BASE if OS.is_debug_build() else RELEASE_BASE
	_main_path = base + ".json"
	_backup_path = base + ".bak"
	_temp_path = base + ".tmp"
	load_game()


func save() -> void:
	var data: Dictionary = {
		"version": VERSION,
		"hunger": GameState.hunger,
		"cleanliness": GameState.cleanliness,
		"happiness": GameState.happiness,
		"last_ticked_at": GameState.last_ticked_at,
	}

	var temp: FileAccess = FileAccess.open(_temp_path, FileAccess.WRITE)
	if temp == null:
		push_error("Could not open %s for writing: %d" % [_temp_path, FileAccess.get_open_error()])
		return
	temp.store_string(JSON.stringify(data))
	temp.close()

	# Roll the current file back one slot before it is replaced. One save behind
	# is enormously better than gone.
	if FileAccess.file_exists(_main_path):
		DirAccess.rename_absolute(_main_path, _backup_path)
	var renamed: Error = DirAccess.rename_absolute(_temp_path, _main_path)
	if renamed != OK:
		push_error("Could not move %s over %s: %d" % [_temp_path, _main_path, renamed])


## Reads the save and brings the world up to the present. This is the whole
## startup path, which is why the debug panel's Reload From Disk calls it too.
func load_game() -> void:
	var data: Dictionary = _read(_main_path)
	if data.is_empty():
		data = _read(_backup_path)
		if not data.is_empty():
			push_warning("Main save unreadable — restored from %s." % _backup_path)

	if data.is_empty():
		GameState.reset_to_new()
		# Write immediately, so "no save yet" stops being a state to reason about
		# from the very first run onwards.
		save()
		return

	# A version-1 save has no cleanliness or happiness. They read as a fresh
	# Usapyon's starting value and then decay with elapsed time like everything
	# else, rather than arriving at a full bar nothing earned.
	GameState.hunger = float(data.get("hunger", BunnyCareRules.STARTING_VALUE))
	GameState.cleanliness = float(data.get("cleanliness", BunnyCareRules.STARTING_VALUE))
	GameState.happiness = float(data.get("happiness", BunnyCareRules.STARTING_VALUE))
	# A file without a timestamp is treated as having just been written, rather
	# than as 1970 followed by fifty years of decay.
	GameState.last_ticked_at = int(data.get("last_ticked_at", GameState.now()))
	GameState.catch_up_to(GameState.now())


## Throws the save away and starts over. The backup goes too — keeping it would
## make Reset Save something you could undo by accident on the next load.
func reset() -> void:
	DirAccess.remove_absolute(_backup_path)
	DirAccess.remove_absolute(_main_path)
	GameState.reset_to_new()
	save()


## The parsed contents of `path`, or an empty Dictionary if it is missing,
## unreadable or not a JSON object.
func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var text: String = file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if parsed is Dictionary:
		return parsed
	push_warning("%s is not a JSON object." % path)
	return {}
