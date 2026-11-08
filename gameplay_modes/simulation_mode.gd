class_name SimulationMode
extends BaseMode

@export var simulation: SimulationRunner

func _ready() -> void:
	assert(simulation != null, "[SimulationMode] Erreur critique : SimulationRunner non assigné !")


func enter_mode() -> void:
	# Lancement de la simulation
	simulation.start()

func exit_mode() -> void:
	#Arrêt de la simumation
	simulation.stop()
