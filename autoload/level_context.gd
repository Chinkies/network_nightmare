extends Node

var current_level: LevelDefinition
var unlocked_level_ids: Dictionary = {}


func _ready() -> void:
	unlocked_level_ids["level_01"] = true


func is_level_unlocked(level_definition: LevelDefinition) -> bool:
	return level_definition != null and unlocked_level_ids.get(level_definition.level_id, false)


func unlock_level(level_definition: LevelDefinition) -> void:
	if level_definition != null and not level_definition.level_id.is_empty():
		unlocked_level_ids[level_definition.level_id] = true
