extends Node

var PERSONNAGES: Dictionary[String, Personnage] = {
	"N": load("res://personnages/narrateur.tscn").instantiate(),
	"ML01": load("res://personnages/moine_lambda_01.tscn").instantiate(),
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
