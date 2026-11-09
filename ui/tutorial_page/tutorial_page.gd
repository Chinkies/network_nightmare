class_name TutorialPage
extends Resource

@export var title: String = ""
@export_multiline var text: String = ""
@export var image: Texture2D = null
@export_range(10.0, 100.0, 1.0, "suffix:%") var image_width_percent: float = 100.0