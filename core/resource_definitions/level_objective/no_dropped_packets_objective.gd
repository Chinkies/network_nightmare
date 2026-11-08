class_name NoDroppedPacketsObjective
extends LevelObjective

func check_fulfillment(stats: Dictionary) -> bool:
	var dropped = stats.get("dropped_count", 0)
	return dropped == 0