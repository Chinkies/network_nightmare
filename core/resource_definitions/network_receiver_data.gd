class_name NetworkReceiverData
extends NetworkDeviceData

@export_category("Paramètres spécifiques aux Receivers")
@export var expected_color: NetworkPacket.PacketColor = NetworkPacket.PacketColor.BLUE
@export var expected_number: int = 1


func _init() -> void:
	# On force le type par défaut pour cette ressource
	device_type = NetworkDevice.Type.RECEIVER

## Surcharge de la FACTORY
func instantiate_device(unique_id: String) -> NetworkDevice:
	var device = NetworkReceiver.new(
		unique_id, expected_color, expected_number, 
		default_buffer_capacity, default_processing_rate
	)
	return device
