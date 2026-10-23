class_name BaseMode
extends Node

# =====================
# ===== ATTRIBUTS =====
# =====================

## Référence au gestionnaire pour permettre à un mode de déclencher lui-même un changement 
## (ex: le changement d'état implicite lors du drop d'un composant)
var mode_manager: ModeManager


# ====================
# ===== METHODES =====
# ====================

func enter_mode() -> void:
	pass

func exit_mode() -> void:
	pass
	

# ------------------------------
# --- Gestion des évènements ---
# ------------------------------

## Tente d'annuler l'action en cours dans ce mode. 
## Retourne 'true' si une action a été annulée, 'false' s'il n'y avait rien à annuler.
func cancel_action() -> bool:
	return false
