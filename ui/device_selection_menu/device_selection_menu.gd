class_name DeviceSelectionMenu
extends GridContainer

## Liste des devices disponibles
var available_devices: Array[NetworkDeviceData] = []
var current_stocks: Dictionary = {}

@export var slot_scene: PackedScene

## Méthode appelée lors du chargement initial ou du reset
func setup_menu(devices: Array[NetworkDeviceData], stocks: Dictionary) -> void:
	available_devices = devices
	current_stocks = stocks
	populate_menu()


## Met à jour l'affichage des stocks restants en temps réel
func update_stocks(stocks: Dictionary) -> void:
	current_stocks = stocks.duplicate()
	for child in get_children():
		if child is DraggableItem and child.device_data:
			var key = _get_data_stock_key(child.device_data)
			var stock = current_stocks.get(key, 99)
			child.set_stock(stock)


func _get_data_stock_key(data: NetworkDeviceData) -> String:
	match data.device_type:
		NetworkDevice.Type.SWITCH:
			return "switch"
		NetworkDevice.Type.RECEIVER:
			return "receiver"
		NetworkDevice.Type.GENERIC:
			return "generic"
		_:
			return ""

## Génère les éléments dans la grille de sélection
func populate_menu() -> void:
	for child in get_children():
		child.queue_free()
    
	if not slot_scene:
		push_warning("[UIMenuDeviceSelection] Aucune scène de slot assignée !")
		return
    
	for device_data in available_devices:
		if device_data == null:
			continue

		var slot_instance = slot_scene.instantiate() as DraggableItem
		if slot_instance:
			slot_instance.device_data = device_data
			var key = _get_data_stock_key(device_data) # Utilise la bonne clé unifiée ("switch", "receiver", etc.)
			var stock = current_stocks.get(key, 99)
			add_child(slot_instance)
			slot_instance.set_stock(stock)