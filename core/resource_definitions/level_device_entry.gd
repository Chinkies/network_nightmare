class_name LevelDeviceEntry
extends Resource

@export var device_data: NetworkDeviceData
@export var device_id: String = ""
@export var grid_position: Vector2i = Vector2i.ZERO
@export_range(0, 3) var rotation_quadrants: int = 0
@export var is_movable: bool = false
@export var is_deletable: bool = false
