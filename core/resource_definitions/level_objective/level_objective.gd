class_name LevelObjective
extends Resource

@export var objective_id: String = ""
@export var description: String = ""

## Méthode virtuelle à surcharger pour évaluer si l'objectif est atteint
func check_fulfillment(_validator_stats: Dictionary) -> bool:
	return false