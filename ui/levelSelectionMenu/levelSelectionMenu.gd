class_name LevelSelectionMenu
extends Control

@export_file("*.tscn") var first_level_scene: String
@export_file("*.tscn") var main_menu_scene: String

@export var level_button_1: TextureButton
@export var main_menu_button: Button


func _ready() -> void:
	level_button_1.pressed.connect(_on_level_1_pressed)
	main_menu_button.pressed.connect(_on_main_menu_button_pressed)


func _on_level_1_pressed() -> void:
	if first_level_scene.is_empty():
		push_error("[LevelSelectionMenu] Aucun chemin de scène n'a été assigné pour le niveau 1 !")
		return
		
	var error = get_tree().change_scene_to_file(first_level_scene)
	if error != OK:
		push_error("[LevelSelectionMenu] Impossible de charger la scène du niveau : %s" % first_level_scene)

func _on_main_menu_button_pressed() -> void:
	if main_menu_scene.is_empty():
		push_error("[LevelSelectionMenu] Aucun chemin de scène n'a été assigné pour le main menu !")
		return
	
	var error = get_tree().change_scene_to_file(main_menu_scene)
	if error != OK:
		push_error("[LevelSelectionMenu] Impossible de charger la scène du main menu : %s" % main_menu_scene)
