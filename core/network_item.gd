class_name NetworkItem
extends RefCounted

# --- Permissions du Level Design ---

## Si false, l'objet ne peut pas être supprimé par le joueur (utile pour les machines imposées du niveau)
var is_deletable: bool = true

## Si false, l'objet ne peut pas être déplacé via Drag & Drop (EditMode)
var is_movable: bool = true

## Si true, l'objet possède des paramètres modifiables par le joueur (ex: IP, règles de firewall)
var is_configurable: bool = false
