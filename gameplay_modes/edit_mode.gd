class_name EditMode
extends BaseMode

# =====================
# ===== ATTRIBUTS =====
# =====================

@export var grid_board: GridBoard
@export var grid_view: GridView
@export var simulation: SimulationRunner


# =====================
# ===== METHODES  =====
# =====================

func _ready() -> void:
	# Vérification des composants
	assert(grid_board != null, "[EditMode] Erreur critique : GridBoard non assigné !")
	assert(grid_view != null, "[EditMode] Erreur critique : GridView non assigné !")
	assert(simulation != null, "[EditMode] Erreur critique : SimulationRunner non assigné !")

func enter_mode() -> void:
	print("[EditMode] Mode actif. Prêt pour le placement.")

func exit_mode() -> void:
	print("[EditMode] Mode quitté.")


# ---------------------------------------
# --- METHODES SPECIFIQUES AU EDITMODE ---
# ---------------------------------------

func handle_device_drop(cell: Vector2i, device_data: Variant) -> void:
	# 1. Vérification dans le Modèle
	if grid_board.is_cell_occupied(cell):
		print("[EditMode] Case occupée, placement annulé.")
		return

	# 2. Création de la machine logique
	var unique_id = "%s_%d_%d" % [device_data.device_id_template, cell.x, cell.y]
	var logic_device = device_data.instantiate_device(unique_id)
	logic_device.grid_position = cell

	# 3. Création de la machine visuelle
	if not device_data.device_scene:
		push_error("[EditMode] Scène visuelle manquante dans la ressource !")
		return
		
	var view_node = device_data.device_scene.instantiate() as NetworkDeviceView
	
	# On demande au GridView de calculer le centre géométrique
	view_node.global_position = grid_view.cell_to_world_center(cell)
	
	# Le GridView sert de conteneur d'affichage
	grid_view.add_child(view_node)
	view_node.setup(logic_device, device_data.texture, float(grid_view.cell_size))

	# 4. Enregistrement dans les systèmes
	grid_board.set_cell_occupied(cell, view_node)
	simulation.register_device(logic_device)
	
	# 5. Abonnement dynamique : on connecte les signaux du device au ModeManager
	view_node.port_interaction_requested.connect(mode_manager.on_port_interaction_requested)
	
	print("[EditMode] Appareil posé avec succès : ", unique_id)
