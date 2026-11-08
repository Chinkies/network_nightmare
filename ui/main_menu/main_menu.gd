class_name MainMenu
extends Control

@export_file("*.tscn") var level_selection_menu_path: String

@export var level_selection_button: Button
@export var settings_button: Button
@export var exit_button: Button


func _ready() -> void:
	level_selection_button.pressed.connect(_on_level_selection_button_pressed)
	settings_button.pressed.connect(_on_settings_button_pressed)
	exit_button.pressed.connect(_on_exit_button_pressed)


func _on_level_selection_button_pressed() -> void:
	get_tree().change_scene_to_file(level_selection_menu_path)

func _on_settings_button_pressed() -> void:
	print("[MainMenu] TODO : Faire les settings")
	return

func _on_exit_button_pressed() -> void:
	get_tree().quit()