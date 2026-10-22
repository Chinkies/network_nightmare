class_name DraggableItem
extends Control

@export var visual_size: Vector2
@export var margin: Vector2

var device_data: NetworkDeviceData

#pas sur de ça, c'est pour la texture dans l'ui mais ça sera surement récup via le networkDevice
@onready var device_visual: TextureRect = $TextureRect

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_update_visuals()

## Attribue la texture et ajuste sa taille
func _update_visuals() -> void:
	if device_data and device_visual:
		device_visual.texture = device_data.texture
		
		# Autorise le composant à ignorer la taille native de l'image
		device_visual.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		# Garde les proportions de l'image pour ne pas l'écraser
		device_visual.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		
		# Verrouille strictement la taille avec un minimum ET un maximum
		device_visual.custom_minimum_size = visual_size
		device_visual.custom_maximum_size = visual_size
		
		# Force l'application immédiate de la taille
		device_visual.size = visual_size
		
		custom_minimum_size = visual_size + margin

# ==================================
# ===== GESTION DU DRAG & DROP =====
# ==================================

func _get_drag_data(_at_position: Vector2) -> Variant:
	
	if not device_data:
		return null
		
	## Création du control node avec la texture
	var preview_rect := TextureRect.new()
	preview_rect.texture = device_data.texture
	preview_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview_rect.custom_maximum_size = Vector2(48, 48)
	preview_rect.custom_minimum_size = visual_size

	var preview_container := Control.new()
	preview_container.add_child(preview_rect)
	
	## Placement de l'icone sous la souris
	preview_rect.position = -Vector2(visual_size.x * 0.5, visual_size.y * 0.5)

	set_drag_preview(preview_container)

	return {"type": "network_item", "device_data": device_data}
