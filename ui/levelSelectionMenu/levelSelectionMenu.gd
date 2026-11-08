class_name LevelSelectionMenu
extends Control

@export_category("Configuration des Chemins")
@export_file("*.tscn") var level_scene_path: String = "res://levels/level_scene.tscn"
@export_file("*.tscn") var main_menu_scene: String

@export_category("Sélection des Niveaux")
@export var level_definition_1: LevelDefinition

@export_category("Références UI")
@export var level_button_1: TextureButton
@export var main_menu_button: Button


func _ready() -> void:
	level_button_1.pressed.connect(_on_level_1_pressed)
	main_menu_button.pressed.connect(_on_main_menu_button_pressed)
		
	if level_scene_path.is_empty():
		push_error("[LevelSelectionMenu] Le chemin de la scène de jeu (level_scene_path) est vide !")
		return


func _on_level_1_pressed() -> void:
	if not level_definition_1:
		push_error("[LevelSelectionMenu] Aucune ressource LevelDefinition n'a été assignée pour le niveau 1 !")
		return

	if has_node("/root/LevelContext"):
		var context = get_node("/root/LevelContext")
		context.current_level = level_definition_1
	else:
		push_error("[LevelSelectionMenu] L'autoload LevelContext est introuvable !")
		return

	var error = get_tree().change_scene_to_file(level_scene_path)
	if error != OK:
		push_error("[LevelSelectionMenu] Impossible de charger la scène commune : %s" % level_scene_path)

func _on_main_menu_button_pressed() -> void:
	if main_menu_scene.is_empty():
		push_error("[LevelSelectionMenu] Aucun chemin de scène n'a été assigné pour le main menu !")
		return
	
	var error = get_tree().change_scene_to_file(main_menu_scene)
	if error != OK:
		push_error("[LevelSelectionMenu] Impossible de charger la scène du main menu : %s" % main_menu_scene)
