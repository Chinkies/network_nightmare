class_name NoExpiredPacketsObjective
extends LevelObjective

func check_fulfillment(stats: Dictionary) -> bool:
	var expired = stats.get("expired_count", 0)
	return expired == 0