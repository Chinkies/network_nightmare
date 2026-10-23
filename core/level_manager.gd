class_name LevelManager
extends Node

# =====================
# ===== ATTRIBUTS =====
# =====================

@export var mode_manager: ModeManager
# @export var puzzle_ui: PuzzleUiController # Pour plus tard


# ====================
# ===== METHODES =====
# ====================

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			
			# 1. On demande d'abord au ModeManager s'il a une action en cours à annuler
			if mode_manager and mode_manager.cancel_action():
				get_viewport().set_input_as_handled()
				return
				
			# 2. Plus tard : On demandera à l'UI si une fenêtre de configuration est ouverte
			# if puzzle_ui and puzzle_ui.close_top_window():
			# 	get_viewport().set_input_as_handled()
			# 	return
				
			# 3. Si personne n'a consommé le Échap, c'est qu'on est au repos -> Menu Pause
			print("[LevelManager] Rien à annuler : Ouverture du menu de Pause (TODO)")
			get_viewport().set_input_as_handled()
