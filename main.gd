extends Node2D

@onready var menu_accueil: Control = $menu_accueil

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# on connecte le signal quitter à la fonction qui ferme le jeu
	GestionPartie.quitter.connect(quitter)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func nouvellle_partie():
	# on crée fichier de sauvegarde pour la nouvelle partie
	var fichier_sauvegarde = FileAccess.open("user://save.dat", FileAccess.WRITE)
	
	fichier_sauvegarde.store_line(Time.get_date_string_from_system() + ";introduction.dialogue;1")
	
	# on ouvre le jeu
	var interface_dialogue = load("res://interface_dialogue.tscn").instantiate()
	add_child(interface_dialogue)
	
	# on lit la première scène
	interface_dialogue.lire_dialogue("introduction.dialogue")
	
	# on ferme le menu
	menu_accueil.queue_free()


func continuer_partie():
	var fichier_sauvegarde = FileAccess.open("user://save.dat", FileAccess.READ)
	
	var dernière_sauvegarde = fichier_sauvegarde.get_as_text().split("\n", false)[-1].split(";")
	
	# on lance le dialogue où le joueur l'avait sauvegardé
	var interface_dialogue = load("res://interface_dialogue.tscn").instantiate()
	add_child(interface_dialogue)
	
	interface_dialogue.lire_dialogue(dernière_sauvegarde[1], int(dernière_sauvegarde[2]))
	
	menu_accueil.queue_free()


func _on_bouton_charger_pressed() -> void:
	var écran = load("res://écran_parties_sauvegardées.tscn").instantiate()
	var interface_dialogue = load("res://interface_dialogue.tscn").instantiate()
	
	add_child(interface_dialogue)
	add_child(écran)


func quitter():
	get_tree().quit()
