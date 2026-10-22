class_name ModeManager
extends Node


# ======================
# ===== ATTRIBUTS ======
# ======================

var current_mode: BaseMode
var previous_mode: BaseMode

@onready var edit_mode = $EditMode
#@onready var wiring_mode = $WiringMode
#@onready var delete_mode = $DeleteMode
#@onready var simulation_mode = $SimulationMode


# =====================
# ===== METHODES ======
# =====================

func _ready() -> void:
	# Injection de dépendance : on donne aux enfants l'accès au manager
	for child in get_children():
		if child is BaseMode:
			child.mode_manager = self
			
	# État initial au lancement
	call_deferred("switch_mode", edit_mode)


# -------------------------
# --- GESTION DES MODES ---
# -------------------------

func switch_mode(new_mode: BaseMode, save_history: bool = false) -> void:
	if current_mode == new_mode:
		return
		
	if save_history and current_mode:
		previous_mode = current_mode
		
	if current_mode:
		current_mode.exit_mode()
		
	current_mode = new_mode
	
	if current_mode:
		current_mode.enter_mode()


func switch_to_previous_mode() -> void:
	if previous_mode:
		switch_mode(previous_mode, false)
		previous_mode = null


func _unhandled_input(event: InputEvent) -> void:
	# On s'assure que c'est une pression de touche (et non un maintien prolongé)
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_C:
				switch_mode(edit_mode)
				print("[ModeManager] Bascule : CREATE (EditMode)")
			KEY_W:
				# switch_mode(wiring_mode)
				print("[ModeManager] Bascule : WIRING")
			KEY_X:
				# On active la sauvegarde de l'historique pour pouvoir revenir au mode précédent plus tard
				# switch_mode(delete_mode, true) 
				print("[ModeManager] Bascule : DELETE")
			KEY_R:
				# switch_mode(simulation_mode)
				print("[ModeManager] Bascule : RUN (Simulation)")


# -------------------------------------
# --- ROUTAGE DES ENTREES DU JOUEUR ---
# -------------------------------------

func on_device_drop_requested(cell: Vector2i, device_data: Variant) -> void:
	# Seuls les modes qui possèdent explicitement cette méthode (Edition, Wiring, Delete) la recevront.
	if current_mode and current_mode.has_method("handle_device_drop"):
		current_mode.handle_device_drop(cell, device_data)
	else:
		# Optionnel : log de debug pour vérifier que le drop est bien bloqué en mode simulation
		# print("[ModeManager] Drop ignoré, mode inadapté.")
		pass


func on_port_interaction_requested(device: NetworkDevice, local_port_id: int) -> void:
	print("[ModeManager] Clic détecté sur le port ", local_port_id, " de l'appareil ", device.id)
	
	# Seul le WiringMode (et éventuellement DeleteMode plus tard si tu veux cliquer sur un port pour supprimer son câble) réagira.
	if current_mode and current_mode.has_method("handle_port_click"):
		current_mode.handle_port_click(device, local_port_id)
