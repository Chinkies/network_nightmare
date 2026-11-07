class_name LevelSelectionMenu
extends Control

@export_file("*.tscn") var first_level_scene: String

@onready var level_button_1: TextureButton = $LevelButtonsContainer/buttonLevel1


func _ready() -> void:
	if level_button_1:
		level_button_1.pressed.connect(_on_level_1_pressed)


func _on_level_1_pressed() -> void:
	if first_level_scene.is_empty():
		push_error("[LevelSelectionMenu] Aucun chemin de scène n'a été assigné pour le niveau 1 !")
		return
		
	var error = get_tree().change_scene_to_file(first_level_scene)
	if error != OK:
		push_error("[LevelSelectionMenu] Impossible de charger la scène du niveau : %s" % first_level_scene)
