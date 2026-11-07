class_name DeleteProgressBar
extends ProgressBar


# =====================
# ===== ATTRIBUTS =====
# =====================

var _tween: Tween


# ====================
# ===== METHODES =====
# ====================

func _ready() -> void:
	# État par défaut au lancement : caché et vide
	visible = false
	value = 0.0
	max_value = 100.0 

## Ajuste la taille en focntion de la taille d'une cellule
func setup_size(cell_size: int) -> void:
	size.x = 0.65 * cell_size
	size.y = 0.07 * cell_size


# --- Interface publique ---

## Place l'UI de manière à ce qu'elle soit parfaitement centrée horizontalement sur la coordonnée donnée
func set_centered_position(target_pos: Vector2) -> void:
	global_position = target_pos - Vector2(size.x / 2.0, 0)


## Lance l'animation de remplissage sur une durée précise (en secondes)
func start_loading(duration: float) -> void:
	visible = true
	value = 0.0
	
	# On tue l'animation précédente si elle existait (sécurité)
	if _tween and _tween.is_valid():
		_tween.kill()
		
	_tween = create_tween()
	
	# On anime la propriété "value" jusqu'à "max_value" pendant "duration" secondes
	_tween.tween_property(self, "value", max_value, duration)
	
	# Une fois le temps écoulé, on cache automatiquement la barre
	_tween.tween_callback(func(): visible = false)


## Interrompt l'animation et cache la barre
func cancel_loading() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
		
	value = 0.0
	visible = false
