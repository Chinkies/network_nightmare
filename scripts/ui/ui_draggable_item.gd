class_name UIDraggableItem
extends Control

var item_data: NetworkDevice

#pas sur de ça, c'est pour la texture dans l'ui mais ça sera surement récup via le networkDevice
@onready var icon_texture: TextureRect = $TextureRect

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_update_visuals()

#attribue la texture
func _update_visuals() -> void:
	if item_data and icon_texture:
		icon_texture.texture = item_data.icon

# ==================================
# ===== GESTION DU DRAG & DROP =====
# ==================================

func _get_drag_data(_at_position: Vector2) -> Variant:
	
	if not item_data:
		return null
		
	## Création du control node avec la texture
	var preview_rect := TextureRect.new()
	preview_rect.texture = item_data.icon
	preview_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview_rect.custom_minimum_size = Vector2(48, 48)

	var preview_container := Control.new()
	preview_container.add_child(preview_rect)
	
	## Placement de l'icone sous la souris
	preview_rect.position = -Vector2(28, 28)

	set_drag_preview(preview_container)

	return {"type": "network_item", "item_data": item_data}