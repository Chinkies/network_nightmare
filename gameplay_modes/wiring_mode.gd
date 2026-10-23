class_name WiringMode
extends BaseMode


# =====================
# ===== ATTRIBUTS =====
# =====================

@export var grid_board: GridBoard

# Mémoire du premier port cliqué
var source_device: NetworkDevice = null
var source_port_id: int = -1


# =====================
# ===== METHODES  =====
# =====================

func _ready() -> void:
	assert(grid_board != null, "[WiringMode] Erreur critique : GridBoard non assigné !")

func enter_mode() -> void:
	grid_board.set_all_ports_interaction_active(true)
	_reset_selection()

func exit_mode() -> void:
	grid_board.set_all_ports_interaction_active(false)
	_reset_selection()


# ------------------------------------------
# --- METHODES SPECIFIQUES AU WIRINGMODE ---
# ------------------------------------------

# --- Interface publique ---

func cancel_action() -> bool:
	if source_device != null:
		print("[WiringMode] Câblage annulé.")
		_reset_selection()
		return true # L'événement est consommé
	return false # Rien n'était en cours


func handle_port_click(device: NetworkDevice, local_port_id: int) -> void:
	# CAS 1 : Aucun port n'est encore sélectionné -> On enregistre la source
	if source_device == null:
		source_device = device
		source_port_id = local_port_id
		# TODO : Ajouter un feedback visuel sur le port source (ex: le laisser en surbrillance)
		
	# CAS 2 : On clique sur le MÊME port -> On annule la sélection
	elif source_device == device and source_port_id == local_port_id:
		_reset_selection()
		
	# CAS 3 : On clique sur un port DIFFÉRENT -> On tente la connexion
	else:
		_attempt_connection(device, local_port_id)


# --- Méthodes privées ---

func _attempt_connection(target_device: NetworkDevice, target_port_id: int) -> void:
	# 1. Vérification logique basique (ex: on ne relie pas une machine à elle-même)
	if source_device == target_device:
		print("[WiringMode] Erreur : Impossible de relier un appareil à lui-même.")
		_reset_selection()
		return
		
	# TODO : Vérifier via la grille si le chemin physique est libre
	# TODO : Instancier le NetworkWire logique et visuel
	
	print("[WiringMode] SUCCÈS : Connexion établie entre ", source_device.id, " et ", target_device.id)
	_reset_selection()


func _reset_selection() -> void:
	source_device = null
	source_port_id = -1
	# TODO : Retirer la surbrillance du port source si elle était active
