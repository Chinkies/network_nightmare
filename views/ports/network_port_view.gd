class_name NetworkPortView
extends Area2D


# --- Signaux ---

## Signal émis quand le joueur clique sur ce port
signal port_clicked(port_id: int)


# --- Enumérations ---

enum PortState { AVAILABLE, SELECTED, COMPATIBLE, INCOMPATIBLE, OCCUPIED_INPUT, OCCUPIED_OUTPUT }


# =====================
# ===== ATTRIBUTS =====
# =====================

@export_group("Couleurs")
@export var available_color: Color = Color("00f0ffd2") # Cyan holographique
@export var incompatible_color: Color = Color(1.0, 0.2, 0.2, 0.6) # Rouge translucide
@export var occupied_color: Color = Color(0.55, 0.55, 0.55, 0.6) # Gris, opacité très faible
@export var outline_color: Color = Color.YELLOW # Couleur du contour de sélection
@export_group("Textures")
@export var static_flow_texture: Texture2D

@onready var background: Sprite2D = $Background
@onready var icon: Sprite2D = $Icon

var port_id: int = -1
var current_state: PortState = PortState.AVAILABLE
var origin_texture: Texture2D
var origin_rotation: float
var output_direction: Vector2


# Gestion de l'animation
var base_scale: Vector2 = Vector2.ONE
var hover_tween: Tween
var is_hovered: bool = false
var is_pulsing: bool = false



# ====================
# ===== METHODES =====
# ====================

func _ready() -> void:
	# On vérifie que la texture de flow statique est assignée
	assert(static_flow_texture != null, "[NetworkPortView] Erreur critique : Texture de flow statique non assignée !")
	
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
func setup(p_id: int, p_texture: Texture2D, p_rotation: float, p_output_direction: Vector2) -> void:
	port_id = p_id
	origin_texture = p_texture
	origin_rotation = p_rotation
	output_direction = p_output_direction
	
	if icon:
		icon.texture = p_texture
		icon.rotation = p_rotation
		
	set_visual_state(PortState.AVAILABLE)



# --------------------------------
# --- GETTERS DE L'ETAT VISUEL ---
# --------------------------------

func is_in_occupied_state() -> bool:
	return current_state == PortState.OCCUPIED_INPUT or current_state == PortState.OCCUPIED_OUTPUT

func is_in_compatibility_state() -> bool: 
	return current_state == PortState.COMPATIBLE or current_state == PortState.INCOMPATIBLE or current_state == PortState.SELECTED



# --------------------------------
# --- GESTION DE L'ETAT VISUEL ---
# --------------------------------

## Modifie l'état visuel et interactif du port
func set_visual_state(new_state: PortState) -> void:
	current_state = new_state
	
	# Force le retour du diamètre à la normale
	if hover_tween and hover_tween.is_valid():
		hover_tween.kill()
	scale = base_scale
	is_hovered = false 
	
	match current_state:
		PortState.AVAILABLE, PortState.SELECTED:
			icon.texture = origin_texture
			icon.rotation = origin_rotation
			background.modulate = available_color
			icon.modulate.a = 0.82
			is_pulsing = false
			input_pickable = true
		
		PortState.COMPATIBLE:
			icon.texture = origin_texture
			icon.rotation = origin_rotation
			background.modulate = available_color	#Color(0., 0.8, 0.3, 1)
			icon.modulate.a = 0.82
			is_pulsing = true
			input_pickable = true
		
		PortState.INCOMPATIBLE:
			icon.texture = origin_texture
			icon.rotation = origin_rotation
			background.modulate = incompatible_color
			icon.modulate.a = incompatible_color.a
			is_pulsing = false
			input_pickable = false
		
		PortState.OCCUPIED_INPUT:
			icon.texture = static_flow_texture
			icon.rotation = (-output_direction).angle()
			background.modulate = occupied_color
			icon.modulate.a = occupied_color.a
			is_pulsing = false
			input_pickable = false
		
		PortState.OCCUPIED_OUTPUT:
			icon.texture = static_flow_texture
			icon.rotation = output_direction.angle()
			background.modulate = occupied_color
			icon.modulate.a = occupied_color.a
			is_pulsing = false
			input_pickable = false
		
	# Déclenche l'appel à la fonction native _draw() pour afficher ou masquer le contour
	queue_redraw()


## Affiche/Masque le port. S'il est masqué, la détection est suspendue.
func set_visibility(p_visible: bool) -> void:
	visible = p_visible
	
	if not visible:
		input_pickable = false
		is_pulsing = false
	else:
		input_pickable = not ( is_in_occupied_state() or current_state == PortState.INCOMPATIBLE )


## Fonction native de dessin 2D dans Godot
func _draw() -> void:
	if current_state == PortState.SELECTED and background and background.texture:
		var radius = background.texture.get_width() / 2.0
		# Les paramètres : centre, rayon, angle de départ, angle de fin, segments, couleur, épaisseur, antialiasing
		draw_arc(Vector2.ZERO, radius, 0, TAU, 32, outline_color, 8.0, true)



# ------------------------------
# --- GESTION DE LA ROTATION ---
# ------------------------------

## Met à jour les variables internes suite à une rotation de la machine
func update_internal_rotation(p_rotation: float, p_output_direction: Vector2) -> void:
	origin_rotation = p_rotation
	output_direction = p_output_direction
	
	# Rafraîchissement direct de l'icône selon l'état actuel
	if current_state == PortState.OCCUPIED_INPUT:
		icon.rotation = (-output_direction).angle()
	elif current_state == PortState.OCCUPIED_OUTPUT:
		icon.rotation = output_direction.angle()
	else:
		icon.rotation = origin_rotation


# -------------------------------------
# --- LOGIQUE D'ANIMATION (PROCESS) ---
# -------------------------------------

func _process(_delta: float) -> void:
	# On ne modifie pas l'échelle via _process si la souris est dessus (le Tween prend le relais)
	if is_hovered:
		return
		
	if is_pulsing:
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
	is_hovered = true
	if hover_tween and hover_tween.is_valid():
		hover_tween.kill()
		
	hover_tween = create_tween()
	hover_tween.tween_property(self, "scale", base_scale * 1.3, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_mouse_exited() -> void:
	is_hovered = false
	if hover_tween and hover_tween.is_valid():
		hover_tween.kill()
		
	hover_tween = create_tween()
	hover_tween.tween_property(self, "scale", base_scale, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		get_viewport().set_input_as_handled() 
		port_clicked.emit(port_id)
