class_name MaxDurationObjective
extends LevelObjective

@export var maximum_duration: float = 60.0

func check_fulfillment(stats: Dictionary) -> bool:
	var duration = stats.get("elapsed_time", 0.0)
	return duration <= maximum_duration