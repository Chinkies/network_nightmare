class_name MaxDeviceCountObjective
extends LevelObjective

@export var maximum_device_count: int = 5

func check_fulfillment(stats: Dictionary) -> bool:
	var placed = stats.get("placed_devices_count", 0)
	return placed <= maximum_device_count