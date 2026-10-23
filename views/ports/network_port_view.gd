class_name NetworkPortView
extends Area2D


# --- Signaux ---

## Signal émis quand le joueur clique sur ce port
signal port_clicked(port_id: int)
## Signal émis quand le joueur clique sur un port incompatible
signal invalid_port_clicked(port_id: int)


# --- Enumérations ---

enum PortState { AVAILABLE, SELECTED, INCOMPATIBLE, OCCUPIED }


# =====================
# ===== ATTRIBUTS =====
# =====================

@export_group("Couleurs")
@export var available_color: Color = Color("00f0ffd2") # Cyan holographique
@export var incompatible_color: Color = Color(1.0, 0.2, 0.2, 0.6) # Rouge translucide
@export var occupied_color: Color = Color(0.55, 0.55, 0.55, 0.6) # Gris, opacité très faible
@export var outline_color: Color = Color.YELLOW # Couleur du contour de sélection

@onready var background: Sprite2D = $Background
@onready var icon: Sprite2D = $Icon

var port_id: int = -1
var current_state: PortState = PortState.AVAILABLE

# Gestion de l'animation
var base_scale: Vector2 = Vector2.ONE
var hover_tween: Tween
var is_hovered: bool = false
var is_pulsing: bool = false



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
	
	# Force les sprites à s'afficher sous le _draw() de ce script parent
	background.show_behind_parent = true
	icon.show_behind_parent = true


## Configure l'affichage brut du port (appelé par le parent)
func setup(p_id: int, p_texture: Texture2D, p_rotation: float) -> void:
	port_id = p_id
	
	if icon:
		icon.texture = p_texture
		icon.rotation = p_rotation
		
	set_state(PortState.AVAILABLE)


# --------------------------------
# --- GESTION DE L'ETAT VISUEL ---
# --------------------------------

## Modifie l'état visuel et interactif du port
func set_state(new_state: PortState) -> void:
	current_state = new_state
	
	# Par défaut, le port est cliquable (même pour émettre l'erreur Incompatible)
	input_pickable = true 
	
	# Force le retour du diamètre à la normale
	if hover_tween and hover_tween.is_valid():
		hover_tween.kill()
	scale = base_scale
	is_hovered = false 
	
	match current_state:
		PortState.AVAILABLE, PortState.SELECTED:
			background.modulate = available_color
			icon.modulate.a = 0.82
		PortState.INCOMPATIBLE:
			background.modulate = incompatible_color
			icon.modulate.a = incompatible_color.a
		PortState.OCCUPIED:
			background.modulate = occupied_color
			icon.modulate.a = occupied_color.a
			input_pickable = false
			
	# Déclenche l'appel à la fonction native _draw() pour afficher ou masquer le contour
	queue_redraw()


## Affiche/Masque le port. S'il est masqué, la détection est suspendue.
func set_interaction_active(active: bool) -> void:
	visible = active
	
	if not active:
		input_pickable = false
		set_pulsing(false)
	else:
		# On réactive le clic uniquement si le port n'est pas déjà occupé
		input_pickable = (current_state != PortState.OCCUPIED)


## Active ou désactive la pulsation synchronisée
func set_pulsing(active: bool) -> void:
	is_pulsing = active


## Fonction native de dessin 2D dans Godot
func _draw() -> void:
	if current_state == PortState.SELECTED and background and background.texture:
		var radius = background.texture.get_width() / 2.0
		# Les paramètres : centre, rayon, angle de départ, angle de fin, segments, couleur, épaisseur, antialiasing
		draw_arc(Vector2.ZERO, radius, 0, TAU, 32, outline_color, 8.0, true)


# ------------------------------------
# --- LOGIQUE D'ANIMATION (PROCESS) --
# ------------------------------------

func _process(_delta: float) -> void:
	# On ne modifie pas l'échelle via _process si la souris est dessus (le Tween prend le relais)
	if is_hovered:
		return
		
	if is_pulsing and current_state == PortState.AVAILABLE:
		# Utilisation du temps global pour une synchronisation mathématique absolue
		var time_sec = Time.get_ticks_msec() / 1000.0
		# Onde sinusoïdale remappée de 0 à 1
		var wave = (sin(time_sec * 6.0) + 1.0) / 2.0 
		scale = base_scale * (1.0 + (0.15 * wave)) # Oscillation douce entre 100% et 115%
	elif not hover_tween or not hover_tween.is_running():
		# On s'assure que le port retrouve sa taille d'origine quand il ne pulse plus
		scale = base_scale


# ----------------------------
# --- GESTION DE LA SOURIS ---
# ----------------------------

func _on_mouse_entered() -> void:
	if current_state == PortState.INCOMPATIBLE or current_state == PortState.OCCUPIED:
		return # Aucun feedback visuel sur les ports invalides
		
	is_hovered = true
	if hover_tween and hover_tween.is_valid():
		hover_tween.kill()
		
	hover_tween = create_tween()
	hover_tween.tween_property(self, "scale", base_scale * 1.3, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_mouse_exited() -> void:
	if current_state == PortState.INCOMPATIBLE or current_state == PortState.OCCUPIED:
		return
		
	is_hovered = false
	if hover_tween and hover_tween.is_valid():
		hover_tween.kill()
		
	hover_tween = create_tween()
	hover_tween.tween_property(self, "scale", base_scale, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		get_viewport().set_input_as_handled() 
		
		# On sépare le clic valide du clic erreur pour le game design
		if current_state == PortState.INCOMPATIBLE:
			invalid_port_clicked.emit(port_id)
		elif current_state == PortState.AVAILABLE or current_state == PortState.SELECTED:
			port_clicked.emit(port_id)
