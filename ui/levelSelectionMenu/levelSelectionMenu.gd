class_name LevelSelectionMenu
extends Control

@export_category("Configuration des Chemins")
@export_file("*.tscn") var level_scene_path: String = "res://levels/level_scene.tscn"
@export_file("*.tscn") var main_menu_scene: String

@export_category("Sélection des Niveaux")
@export var level_definitions: Array[LevelDefinition] = []

@export_category("Références UI")
@export var level_buttons: Array[TextureButton] = []
@export var main_menu_button: Button


func _ready() -> void:
	if main_menu_button:
		main_menu_button.pressed.connect(_on_main_menu_button_pressed)
		
	if level_scene_path.is_empty():
		push_error("[LevelSelectionMenu] Le chemin de la scène de jeu (level_scene_path) est vide !")
		return

	for i in range(level_buttons.size()):
		var btn = level_buttons[i]
		if btn:
			if i >= level_definitions.size() or level_definitions[i] == null:
				btn.disabled = true
				continue

			btn.disabled = not _is_level_unlocked(level_definitions[i], i)
				
			if not btn.pressed.is_connected(_on_level_button_pressed):
				btn.pressed.connect(_on_level_button_pressed.bind(i))


func _is_level_unlocked(level_definition: LevelDefinition, level_index: int) -> bool:
	var context = get_node_or_null("/root/LevelContext")
	if context and context.has_method("is_level_unlocked"):
		return context.is_level_unlocked(level_definition)
	return level_index == 0


func _on_level_button_pressed(level_index: int) -> void:
	if level_index < 0 or level_index >= level_definitions.size():
		push_error("[LevelSelectionMenu] Index de niveau invalide : %d" % level_index)
		return
		
	var level_def = level_definitions[level_index]
	if not level_def:
		push_error("[LevelSelectionMenu] Aucune ressource LevelDefinition assignée pour le niveau %d !" % (level_index + 1))
		return

	if has_node("/root/LevelContext"):
		var context = get_node("/root/LevelContext")
		context.current_level = level_def
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
