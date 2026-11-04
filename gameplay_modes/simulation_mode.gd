class_name SimulationMode
extends BaseMode

@export var grid_board: GridBoard
@export var simulation: SimulationRunner

func _ready() -> void:
	assert(grid_board != null, "[SimulationMode] Erreur critique : Gridboard non assigné !")
	assert(simulation != null, "[SimulationMode] Erreur critique : SimulationRunner non assigné !")


func enter_mode() -> void:
	# Désactivation des intéractions ports et drops
	grid_board.set_all_ports_interaction_active(false)

	# Lancement de la simulation
	simulation.start()
	print("[SimulationMode] Entrée en mode Simulation. Édition verrouillée.")

func exit_mode() -> void:
	#Arrêt de la simumation
	simulation.stop()
	print("[SimulationMode] Sortie du mode Simulation.")