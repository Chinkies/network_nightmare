class_name PauseMenu
extends Control

@export var resume_button: Button
@export var level_selection_button: Button
@export var main_menu_button: Button

@export_file("*.tscn") var level_selection_path: String


func _ready() -> void:
	hide()
	
	if resume_button: resume_button.pressed.connect(resume_game)
	if level_selection_button: level_selection_button.pressed.connect(go_to_level_selection)
	if main_menu_button: main_menu_button.pressed.connect(go_to_main_menu)


func open() -> void:
	show()
	get_tree().paused = true

func _unhandled_input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			resume_game()
			get_viewport().set_input_as_handled()
			
func resume_game() -> void:
	hide()
	get_tree().paused = false

func go_to_level_selection() -> void:
	get_tree().paused = false
	if not level_selection_path.is_empty():
		get_tree().change_scene_to_file(level_selection_path)
	else:
		push_error("[PauseMenu] Chemin de la carte non défini !")


func go_to_main_menu() -> void:
	go_to_level_selection()