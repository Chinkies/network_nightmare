class_name NetworkPacket
extends RefCounted

# --- Enums propre à la classe ---

enum PacketColor { BLUE, RED, GREEN, YELLOW }
enum PacketShape { CIRCLE, SQUARE, TRIANGLE }


# --- Attributs ---

var id: int
var target_number: int 
var color: PacketColor
var shape: PacketShape

var routing_history: Dictionary[String, int] = {}	# (clé: String (id du switch), valeur: int (port))

var ttl: float = -1.0 	#Time-To-Live, -1 pour un paquet non éphémère
var is_expired: bool = false


# --- Méthodes ---

func _init(p_id: int, p_target_number: int, p_color: PacketColor, p_shape: PacketShape, p_ttl: float = -1.0) -> void:
	id = p_id
	target_number = p_target_number
	color = p_color
	shape = p_shape
	ttl = p_ttl


# Méthode pour dupliquer un paquet
func clone() -> NetworkPacket:
	var copy = NetworkPacket.new(id, target_number, color, shape, ttl)
	copy.is_expired = is_expired
	# Copie profonde de l'historique
	copy.routing_history = routing_history.duplicate(true)
	return copy


# Appelé uniquement par le manager sur la liste globale des paquets éphémères
func update_ttl(delta: float) -> bool:
	if ttl < 0.0:
		return false
	ttl -= delta
	if ttl <= 0.0:
		ttl = 0.0
		is_expired = true
		return true # Signal d'expiration au manager pour le sortir de la liste
	return false
