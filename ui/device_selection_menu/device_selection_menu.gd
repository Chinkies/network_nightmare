class_name DeviceSelectionMenu
extends GridContainer

## Liste des devices disponibles
var available_devices: Array[NetworkDeviceData] = []

@export var slot_scene: PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not available_devices.is_empty():
		populate_menu()

## Méthode appelée lors du chargement du json
func setup_menu(devices: Array[NetworkDeviceData]) -> void:
	available_devices = devices
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
	for device_data in available_devices:
		if device_data == null:
			continue

		var slot_instance = slot_scene.instantiate() as DraggableItem
		if slot_instance:
			slot_instance.device_data = device_data
			add_child(slot_instance)
