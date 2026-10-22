class_name NetworkDeviceData
extends Resource


@export_category("Informations Générales")
@export var device_id_template: String = "generic"
@export var device_type: NetworkDevice.Type = NetworkDevice.Type.GENERIC
@export var device_name: String = "Appareil Réseau"

@export_category("Apparence & Visuel")
@export var texture: Texture2D
@export var device_scene: PackedScene

@export_category("Paramètres matériels par défaut")
@export var default_buffer_capacity: int = 5
@export var default_processing_rate: float = 2.0


## Device Factory
func instantiate_device(unique_id: String) -> NetworkDevice:
	var device: NetworkDevice
	if device_type == NetworkDevice.Type.SWITCH:
		device = NetworkSwitch.new(unique_id, default_buffer_capacity, default_processing_rate)
	else:
		device = NetworkDevice.new(unique_id, default_buffer_capacity, default_processing_rate)
		device.device_type = device_type

	return device
