class_name Main
extends Node2D

# =====================
# ===== ATTRIBUTS =====
# =====================

@onready var ui_puzzle: UIPuzzleController = %UiPuzzle
@onready var simulation: NetworkSimulation = %NetworkSimulation


# ====================
# ===== METHODES =====
# ====================

func _ready() -> void:
	_connect_ui_signals()


func _connect_ui_signals() -> void:
	ui_puzzle.simulation_started.connect(_on_simulation_started)
	ui_puzzle.simulation_stopped.connect(_on_simulation_stopped)
	ui_puzzle.hint_requested.connect(_on_hint_requested)


func _on_simulation_started() -> void:
	simulation.start()
	print("[Simulation] Démarrée.")


func _on_simulation_stopped() -> void:
	simulation.stop()
	print("[Simulation] Arrêtée.")


func _on_hint_requested() -> void:
	print("[UI] Demande d'indice reçue.")
	# TODO: Afficher le dialogue ou la popup d'indice
