class_name NetworkTransmitterData
extends NetworkDeviceData

@export_category("Paramètres spécifiques aux Transmitter")
@export var emission_schedule: Array[ScheduleEvent] = []

func _init() -> void:
	device_type = NetworkDevice.Type.TRANSMITTER

## Surcharge de la FACTORY
func instantiate_device(unique_id: String) -> NetworkDevice:
	
	var device = NetworkTransmitter.new(
		unique_id, emission_schedule, default_buffer_capacity, default_processing_rate
	)
	return device