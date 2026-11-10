class_name MaximumDeviceCountObjective
extends LevelObjective

@export var max_device_counts: Dictionary[NetworkDevice.Type, int] = {}

func check_fulfillment(stats: Dictionary) -> bool:
	var placed_devices: Array = stats.get("placed_devices_details", [])
	
	if max_device_counts.is_empty():
		return true
		
	var counts_per_type: Dictionary = {}
	for device in placed_devices:
		if device and "device_type" in device:
			var dtype: int = device.device_type
			counts_per_type[dtype] = counts_per_type.get(dtype, 0) + 1
			
	for dtype_key in max_device_counts.keys():
		var dtype_int: int = int(dtype_key)
		var max_allowed = max_device_counts[dtype_key]
		var current_count = counts_per_type.get(dtype_int, 0)
		
		if current_count > max_allowed:
			return false
			
	return true