class_name DeleteMode
extends BaseMode


# =====================
# ===== ATTRIBUTS =====
# =====================

@export var grid_board: GridBoard

var delete_timer: Timer
var target_item: Variant = null 


# ====================
# ===== METHODES =====
# ====================

func _ready() -> void:
	# Création du chronomètre interne
	delete_timer = Timer.new()
	delete_timer.wait_time = 2.0
	delete_timer.one_shot = true
	delete_timer.timeout.connect(_on_delete_timeout)
	add_child(delete_timer)


# --------------------------------
# --- Entrée et sortie du mode ---
# --------------------------------

func enter_mode() -> void:
	print("[DeleteMode] Prêt à détruire.")

func exit_mode() -> void:
	cancel_action()


func cancel_action() -> bool:
	if not delete_timer.is_stopped():
		_stop_deletion()
		return true
	return false


# --------------------------------
# --- Réception des événements ---
# --------------------------------

func handle_item_interaction_started(item: Variant) -> void:
	target_item = item
	delete_timer.start()
	print("[DeleteMode] Suppression commencée... Maintenez le clic.")
	# TODO plus tard : Déclencher un feedback visuel (barre de chargement, clignotement rouge, etc.)


func handle_item_interaction_ended(item: Variant) -> void:
	if target_item == item:
		_stop_deletion()
		print("[DeleteMode] Suppression annulée.")


# ----------------------
# --- Logique privée ---
# ----------------------

func _stop_deletion() -> void:
	delete_timer.stop()
	target_item = null
	# TODO plus tard : Stopper le feedback visuel

func _on_delete_timeout() -> void:
	if target_item != null:
		print("[DeleteMode] BOOM ! Destruction validée.")
		
		# On demande au GridBoard de nettoyer la grille et détruire l'objet logique + sa vue
		if target_item is NetworkWire:
			# grid_board.remove_wire(target_item)
			pass 
		elif target_item is NetworkDevice:
			# grid_board.remove_device(target_item)
			pass
			
		target_item = null
