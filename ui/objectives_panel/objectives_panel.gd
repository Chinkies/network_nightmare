class_name ObjectivesPanel
extends PanelContainer

@export var header_button: Button
@export var content_container: VBoxContainer
@export var bonus_stats_container: VBoxContainer

@export var lbl_processed: Label
@export var lbl_dropped: Label
@export var lbl_tx_buffer: Label

var is_open: bool = false
var is_session_active: bool = false
var total_expected_packets: int = 0

func _ready() -> void:
	if header_button:
		header_button.pressed.connect(_on_header_pressed)
	
	_set_open_state(false)
	if bonus_stats_container:
		bonus_stats_container.visible = false


## Clic utilisateur pour ouvrir/fermer (uniquement hors session active)
func _on_header_pressed() -> void:
	if is_session_active:
		return
	
	_set_open_state(!is_open)


func _set_open_state(open: bool) -> void:
	is_open = open
	if content_container:
		content_container.visible = is_open
	
	if header_button:
		if is_session_active:
			header_button.text = "● Simulation en cours..."
		else:
			header_button.text = "▼ Objectifs" if is_open else "▲ Objectifs"


## Gère l'état actif de la session (Lancé / En pause vs Réinitialisé)
func set_session_active(active: bool) -> void:
	is_session_active = active
	
	if is_session_active:
		_set_open_state(true)
		if header_button:
			header_button.disabled = true
		if bonus_stats_container:
			bonus_stats_container.visible = true
	else:
		if header_button:
			header_button.disabled = false
		if bonus_stats_container:
			bonus_stats_container.visible = false
		_set_open_state(false)


## Initialise les objectifs et le total des paquets
func setup_objectives(objectives: Array[LevelObjective], emission_schedule_size: int) -> void:
	if not content_container:
		return
		
	for child in content_container.get_children():
		child.queue_free()
		
	for obj in objectives:
		var lbl = Label.new()
		lbl.text = "• " + (obj.description if not obj.description.is_empty() else obj.objective_id)
		content_container.add_child(lbl)
	
	total_expected_packets = emission_schedule_size


## Met à jour les métriques bonus en temps réel
func update_live_metrics(processed: int, dropped: int, tx_current: int, tx_initial: int) -> void:
	if lbl_processed:
		lbl_processed.text = "Traités : %d / %d" % [processed, total_expected_packets]
	if lbl_dropped:
		lbl_dropped.text = "Perdus / Expirés : %d" % dropped
	if lbl_tx_buffer:
		lbl_tx_buffer.text = "Buffer Transmitter : %d / %d" % [tx_current, tx_initial]