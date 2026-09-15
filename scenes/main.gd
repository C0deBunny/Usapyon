extends Control

## The debug panel is instanced here rather than sitting in main.tscn, so that a
## release export never has it in the tree — one codebase, two builds, per
## docs/conventions.md. It is still a child of the scene players actually load,
## so testing with it open tests the real scene.

const DEBUG_PANEL_SCENE: PackedScene = preload("res://scenes/debug_panel.tscn")


func _ready() -> void:
	if OS.is_debug_build():
		add_child(DEBUG_PANEL_SCENE.instantiate())
