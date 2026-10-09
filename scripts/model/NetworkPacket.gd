class_name NetworkPacket
extends RefCounted

# --- Enums propre à la classe ---

enum PacketColor { BLUE, RED, GREEN, YELLOW }
enum PacketShape { CIRCLE, SQUARE, TRIANGLE }


# --- Attributs ---

var id: int
var color: PacketColor
var shape: PacketShape

var ttl: float = -1.0 	#Time-To-Live, -1 pour un paquet non éphémère
var is_expired: bool = false

var payload: Dictionary = {}


# --- Méthodes ---

func _init(p_id: int, p_color: PacketColor, p_shape: PacketShape, p_ttl: int = -1, p_payload: Dictionary = {}) -> void:
	id = p_id
	color = p_color
	shape = p_shape
	ttl = p_ttl
	payload = p_payload

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
