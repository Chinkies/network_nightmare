class_name NetworkDeviceData
extends Resource

@export var device_id_template: String = "device"
@export var device_name: String = "Appareil Réseau"
@export var icon: Texture2D
@export var device_type: NetworkDevice.Type = NetworkDevice.Type.GENERIC

@export_category("Paramètres matériels par défaut")
@export var default_buffer_capacity: int = 5
@export var default_processing_rate: float = 2.0

@export_category("Paramètres spécifique aux Receivers")
@export var expected_color: NetworkPacket.PacketColor = NetworkPacket.PacketColor.BLUE
@export var expected_number: int = 1

@export_category("Scène physique")
@export var device_scene: PackedScene

## FACTORY
func instantiate_device(unique_id: String) -> NetworkDevice:
	var device: NetworkDevice = null

	match device_type:
		NetworkDevice.Type.SWITCH:
			device = NetworkSwitch.new(unique_id, default_buffer_capacity, default_processing_rate)
		NetworkDevice.Type.RECEIVER:
			device = NetworkReceiver.new(unique_id, expected_color, expected_number, default_buffer_capacity, default_processing_rate)
		_:
			device = NetworkDevice.new(unique_id, default_buffer_capacity, default_processing_rate)
			device.device_type = device_type;

	device.icon = icon
	return device