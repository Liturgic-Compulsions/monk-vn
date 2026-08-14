extends Control

@onready var menu: VBoxContainer = $CenterContainer/menu
@onready var bouton_nouveau: Button = $CenterContainer/menu/bouton_nouveau
@onready var bouton_continuer: Button = $CenterContainer/menu/bouton_continuer
@onready var bouton_options: Button = $CenterContainer/menu/bouton_options
@onready var bouton_quitter: Button = $CenterContainer/menu/bouton_quitter

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	bouton_continuer.disabled = not FileAccess.file_exists("user://save.dat")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
