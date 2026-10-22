class_name NetworkPortView
extends Area2D


# --- Signaux ---

## Signal émis quand le joueur clique sur ce port
signal port_clicked(port_id: int)


# --- Enumérations ---

enum PortState { AVAILABLE, OCCUPIED, INCOMPATIBLE }


# =====================
# ===== ATTRIBUTS =====
# =====================

@export_group("Couleurs")
@export var available_color: Color = Color("00f0ffd2") # Cyan holographique
@export var occupied_color: Color = Color(0.3, 0.3, 0.3, 0.4) # Gris translucide

@onready var background: Sprite2D = $Background
@onready var icon: Sprite2D = $Icon

var port_id: int = -1
var current_state: PortState = PortState.AVAILABLE

# Gestion des animations
var base_scale: Vector2 = Vector2.ONE
var pulse_tween: Tween
var hover_tween: Tween



# ====================
# ===== METHODES =====
# ====================

func _ready() -> void:
	# On sauvegarde l'échelle initiale définie dans l'éditeur (ex: 0.2)
	base_scale = scale
	
	# Connexion native des signaux de la souris pour l'Area2D
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	input_event.connect(_on_input_event)
	
	# On applique la couleur du plateau de jeu à l'icône pour l'effet de découpe
	icon.modulate = Color(0.08, 0.1, 0.14) 


## Configure l'affichage brut du port (appelé par le parent)
func setup(p_id: int, p_texture: Texture2D, p_rotation: float) -> void:
	port_id = p_id
	
	if icon:
		icon.texture = p_texture
		icon.rotation = p_rotation
		
	set_state(PortState.AVAILABLE)


## Modifie l'état visuel du port (Couleur + Animation)
func set_state(new_state: PortState) -> void:
	current_state = new_state
	_stop_pulsing()
	
	if current_state == PortState.AVAILABLE:
		background.modulate = available_color
		_start_pulsing()
	else:
		background.modulate = occupied_color
		# On remet l'échelle à sa taille normale au cas où le port était en train de pulser
		scale = base_scale


# ------------------------------------
# --- LOGIQUE D'ANIMATION (TWEENS) ---
# ------------------------------------

func _start_pulsing() -> void:
	if pulse_tween and pulse_tween.is_valid():
		pulse_tween.kill()
	pulse_tween = create_tween().set_loops() # Boucle infinie
	# Grossit à 115% puis revient à la normale, de manière très douce
	pulse_tween.tween_property(self, "scale", base_scale * 1.25, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pulse_tween.tween_property(self, "scale", base_scale, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _stop_pulsing() -> void:
	if pulse_tween and pulse_tween.is_valid():
		pulse_tween.kill()


# ----------------------------
# --- GESTION DE LA SOURIS ---
# ----------------------------

func _on_mouse_entered() -> void:
	if current_state != PortState.AVAILABLE:
		return
	
	_stop_pulsing()
	if hover_tween and hover_tween.is_valid():
		hover_tween.kill()
		
	# Effet de "pop" rapide quand la souris passe dessus (130% de la taille de base)
	hover_tween = create_tween()
	hover_tween.tween_property(self, "scale", base_scale * 1.3, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_mouse_exited() -> void:
	if current_state != PortState.AVAILABLE:
		return
		
	if hover_tween and hover_tween.is_valid():
		hover_tween.kill()
		
	# Retour à la taille normale, puis on relance la pulsation
	hover_tween = create_tween()
	hover_tween.tween_property(self, "scale", base_scale, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	hover_tween.tween_callback(_start_pulsing)


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if current_state != PortState.AVAILABLE:
		return
		
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# Bloque la propagation du clic vers les éléments en dessous (comme la grille)
		get_viewport().set_input_as_handled() 
		port_clicked.emit(port_id)


## Affiche/Masque le port et active/désactive sa détection de souris
func set_interaction_active(active: bool) -> void:
	visible = active
	input_pickable = active # Propriété native de CollisionObject2D (Area2D)
	
	if active and current_state == PortState.AVAILABLE:
		_start_pulsing()
	else:
		_stop_pulsing()
