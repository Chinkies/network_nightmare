class_name LevelEndUi
extends Control

# ===================
# ===== SIGNAUX =====
# ===================
signal restart_requested
signal return_to_selection_requested
signal next_level_requested

# =====================
# ===== ATTRIBUTS =====
# =====================
@export var title_label: Label
@export var success_container: VBoxContainer
@export var failed_container: VBoxContainer
@export var stats_label: Label

@export var restart_button: Button
@export var level_selection_button: Button
@export var next_level_button: Button


# ====================
# ===== METHODES =====
# ====================

func _ready() -> void:
	hide_ui()
	
	if restart_button:
		restart_button.pressed.connect(func(): restart_requested.emit())
	if level_selection_button:
		level_selection_button.pressed.connect(func(): return_to_selection_requested.emit())
	if next_level_button:
		next_level_button.pressed.connect(func(): next_level_requested.emit())


## Affiche l'écran de fin avec les résultats de la validation
func show_result(validation_result: Dictionary, objectives: Array[LevelObjective] = []) -> void:
	var success: bool = validation_result.get("success", false)
	var completed_objs: Array = validation_result.get("objectives_completed", [])
	var failed_objs: Array = validation_result.get("objectives_failed", [])
	var stats: Dictionary = validation_result.get("statistics", {})

	if title_label:
		title_label.text = "VICTOIRE !" if success else "ÉCHEC..."
		title_label.modulate = Color.GREEN if success else Color.RED

	var desc_map: Dictionary = {}
	for obj in objectives:
		if obj:
			var desc = obj.description if not obj.description.is_empty() else obj.objective_id
			desc_map[obj.objective_id] = desc

	_populate_list(success_container, completed_objs, desc_map)

	_populate_list(failed_container, failed_objs, desc_map)

	if stats_label:
		var elapsed = stats.get("elapsed_time", 0.0)
		var delivered = stats.get("delivered_count", 0)
		var dropped = stats.get("dropped_count", 0) + stats.get("expired_count", 0)
		stats_label.text = "Temps : %.1fs\nPaquets livrés : %d\nPaquets perdus : %d" % [elapsed, delivered, dropped]

	if next_level_button:
		next_level_button.visible = success

	visible = true


func hide_ui() -> void:
	visible = false


## Utilitaire pour peupler les listes d'objectifs
func _populate_list(container: VBoxContainer, items: Array, desc_map: Dictionary) -> void:
	if not container:
		return
		
	for child in container.get_children():
		child.queue_free()
		
	if items.is_empty():
		var lbl = Label.new()
		lbl.text = "Aucun"
		container.add_child(lbl)
		return

	for item_id in items:
		var lbl = Label.new()
		lbl.text = desc_map.get(item_id, item_id)
		container.add_child(lbl)

## Renvoie true si l'écran de fin est visible
func is_modal_open() -> bool:
	return visible

## Ferme l'écran de fin et déclenche le redémarrage
func close_active_modals() -> void:
	hide_ui()
	restart_requested.emit()