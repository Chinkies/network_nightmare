class_name UIMenuDeviceSelection
extends GridContainer

## Liste des items disponibles
var available_items: Array[NetworkDeviceData] = []

@export var slot_scene: PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not available_items.is_empty():
		populate_menu()

## Méthode appelée lors du chargement du json
func setup_menu(devices: Array[NetworkDeviceData]) -> void:
	available_items = devices
	populate_menu()

## Génère les éléments dans la grille de sélection
func populate_menu() -> void:
	## Nettoyage
	for child in get_children():
		child.queue_free()
	
	if not slot_scene:
		push_warning("[UIMenuDeviceSelection] Aucune scène de slot assignée !")
		return
	
	## Instanciation des devices
	for item_data in available_items:
		if item_data == null:
			continue

		var slot_instance = slot_scene.instantiate() as UIDraggableItem
		if slot_instance:
			slot_instance.item_data = item_data
			add_child(slot_instance)
