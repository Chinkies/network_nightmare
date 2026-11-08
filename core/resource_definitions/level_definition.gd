class_name LevelDefinition
extends Resource

@export_category("Informations du niveau")
@export var level_id: String = ""
@export var next_level_id: String = ""

@export_category("Configuration de la grille")
@export_range(1, 100) var grid_width: int = 10
@export_range(1, 100) var grid_height: int = 6

@export_category("Devices imposés")
@export var initial_devices: Array[LevelDeviceEntry] = []

@export_category("Devices disponibles")
@export var device_limits: Dictionary = {}

@export_category("Objectifs")
@export var objectives: Array[LevelObjective] = []
