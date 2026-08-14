extends Control

# Called when the node enters the scene tree for the first time.
@onready var liste_sauvegarde: VBoxContainer = $fond/CenterContainer/liste_sauvegarde

func _ready() -> void:
	# on lit le fichier de sauvegarde et on créer une liogne pour chque
	# partie sauvegardé
	# cliquer sur la partie, la charge
	var fichier_sauvegarde = FileAccess.open("user://save.dat", FileAccess.READ)
	
	var liste_ligne = fichier_sauvegarde.get_as_text().split("\n", false)
	
	for fichier in liste_ligne:
		var fichier_tokénisé = fichier.split(";")
		
		var bouton = Button.new()
		bouton.text = fichier_tokénisé[0]
		bouton.pressed.connect(_charger.bind(fichier_tokénisé[1], int(fichier_tokénisé[2])))
		
		liste_sauvegarde.add_child(bouton)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _charger(dialogue: String, curseur: int):
	GestionPartie.partie_chargée.emit(dialogue, curseur)
	
	queue_free()
