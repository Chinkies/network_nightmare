class_name GridDropZone

extends Control

@export var grid_manager: GridManager

# Pourquoi GridDropZone possède une fonction _can_drop_data alors qu'il doit
# juste transmettre où est drop l'item :
# Godot appelle _can_drop_data en continu pendant que le joueur déplace sa 
# souris au-dessus de la zone avec un objet attrapé.
# C'est ce qui permet de changer le petit icone interdit en valide quand on passe
# sur des cases libre

func _ready() -> void:
	size.x = grid_manager.cell_size * grid_manager.grid_width
	size.y = grid_manager.cell_size * grid_manager.grid_height

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not grid_manager:
		return false
	return grid_manager.can_handle_drop(get_global_mouse_position(), data);

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if not grid_manager:
		return
	grid_manager.handle_drop(get_global_mouse_position(), data)