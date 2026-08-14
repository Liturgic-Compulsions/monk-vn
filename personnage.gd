class_name Personnage extends Node2D

@onready var sprite: Sprite2D = $sprite

# la liste des émotions des personnages
enum EMOTIONS_PERSONNAGE {
	INVISIBLE, # n'affiche pas le personnage
	NEUTRE
}

const string_to_émotions: Dictionary[String, EMOTIONS_PERSONNAGE] = {
	"invisible": EMOTIONS_PERSONNAGE.INVISIBLE,
	"neutre": EMOTIONS_PERSONNAGE.NEUTRE
}

@export var identifiant: String = ""
# le portrait du personnage en fonction de l'émotion
@export var portraits: Dictionary[EMOTIONS_PERSONNAGE, Texture2D]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
