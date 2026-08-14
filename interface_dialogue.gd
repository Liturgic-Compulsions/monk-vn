extends Node2D

# hud dialogue
@onready var hud_dialogue: MarginContainer = $hud_dialogue
@onready var boite_nom: PanelContainer = $hud_dialogue/VBoxContainer/boite_nom
@onready var nom_label: RichTextLabel = $hud_dialogue/VBoxContainer/boite_nom/marges_boite_nom/nom_label
@onready var boite_dialogue: PanelContainer = $hud_dialogue/VBoxContainer/boite_dialogue
@onready var réplique_label: RichTextLabel = $hud_dialogue/VBoxContainer/boite_dialogue/marges_boite_dialogue/réplique_label

# hud question
@onready var liste_réponses: VBoxContainer = $conteneur_réponses/liste_réponses

# hud controls
@onready var hud_controle: HBoxContainer = $hud_controle
@onready var bouton_option: Button = $hud_controle/bouton_option
@onready var bouton_sauvegarder: Button = $hud_controle/bouton_sauvegarder
@onready var bouton_quitter: Button = $hud_controle/bouton_quitter

# marqueurs scènes
@onready var scène_gauche: Marker2D = $scène_gauche
@onready var scène_centre: Marker2D = $scène_centre
@onready var scène_droite: Marker2D = $scène_droite
@onready var coulisse: Marker2D = $coulisse

# la liste de tous les personnages de la scène
@onready var acteurs: Node2D = $acteurs

# musique
@onready var musique: AudioStreamPlayer = $musique
# arrière plan
@onready var sprite_arrière_plan: Sprite2D = $sprite_arrière_plan


# le dialogue en cours
var dialogue_actuel: Scène

# si une question est en cours, le dialogue ne peut tre continué
# qu'en répondant, cette variable controle donc le déroulement des questions
var question_en_cours: bool = false

# les signaux qui controllent l'avancé des dialogues
signal nouveau_dialogue_commencé(nv_dialogue)
signal prochaine_réplique

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# on lie les signaux de progression
	prochaine_réplique.connect(_prochain_dialogue)
	nouveau_dialogue_commencé.connect(_commencer_dialogue)
	
	# le signal qui permet de charger une partie
	GestionPartie.partie_chargée.connect(lire_dialogue)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _unhandled_input(event: InputEvent) -> void:
	############# DEBUG ###############
	if event.is_action_released("debug"):
		lire_dialogue()
	###################################
	
	if not question_en_cours:
		if event.is_action_released("avancer_dialogue"):
			prochaine_réplique.emit()


func _commencer_dialogue(nv_dialogue):
	dialogue_actuel = nv_dialogue
	
	# on ajoute tous les personnges de la scène en coulisse
	for perso in dialogue_actuel.cast.values():
		acteurs.add_child(perso)
		perso.position = coulisse.position
	
	_afficher_réplique()
	

func _prochain_dialogue():
	dialogue_actuel.curseur += 1
	
	_afficher_réplique()


func _répondre(destination: String):
	if "#" in destination:
		# complexe
		if len(destination.split("#", false)) == 2:
			lire_dialogue(destination.split("#")[0], int(destination.split("#")[1]))
		# simple
		elif len(destination.split("#", false)) == 1:
			dialogue_actuel.curseur = int(destination.rstrip("#"))
			prochaine_réplique.emit()
	else:
		lire_dialogue(destination)
	
	# la question a été répondue, le dialogue peut continuer
	question_en_cours = false

func _afficher_réplique():
	var ligne_actuelle = dialogue_actuel.get_réplique()
	
	# on test si la ligne actuelle du script est une question
	# on commence par vider la liste des réponses
	## si c'est une nouvelle question, on va devoir changer les réponses
	## sinon, il faut effacer les réponses de la qesution précédente
	if liste_réponses.get_children() != []:
		for r: Node in liste_réponses.get_children():
			r.queue_free()
	# maintenant, on oppère les instructions nécessaires si la lgine actuelle est une question
	if ligne_actuelle is Question:
		# une question est affichée à l'écran
		# le dialogue ne peut progresser qu'en y répondant
		question_en_cours = true
		# on remplie la liste des questions
		for réponse in ligne_actuelle.réponses_destinations.keys():
			var bouton_réponse: Button = Button.new()
			bouton_réponse.text = réponse
			bouton_réponse.pressed.connect(_répondre.bind(ligne_actuelle.réponses_destinations[réponse]))
			
			liste_réponses.add_child(bouton_réponse)
	
	# on test si la ligne actuelle du script en indique la fin
	if ligne_actuelle is Fin:
		# s'il s'agit de la dernière ligne du script
		# on charge le script indiqué dans la destination
		# on émet le signal indiquant une nouvelle scène
		# et on return cette fonction
		
		if ligne_actuelle.destination.begins_with("#"):
			dialogue_actuel.curseur = ligne_actuelle.destination.left(-2)
			ligne_actuelle = dialogue_actuel.get_réplique()
		else:
			lire_dialogue(ligne_actuelle.destination)
			return
		
	# on affiche la réplique
	réplique_label.text = ligne_actuelle.réplique
	# on affiche le nom
	nom_label.text = ligne_actuelle.nom_affichage
	# on affiche le personnage
	## on trouve le personnage auquele correspond l'identifiant en début de ligne
	## TODO: peut etre mettre tout ça dans la fonction "commencer dialogu",
	## où on pourrait placer tous les acteurs
	var perso: Personnage = dialogue_actuel.cast[ligne_actuelle.perso_id]
	
	# on détermine où afficher le personnage
	var position_perso: Vector2 = Vector2.ZERO
	match ligne_actuelle.position_scène:
		"G":
			perso.reparent(scène_gauche)
		"C":
			perso.reparent(scène_centre)
		"D":
			perso.reparent(scène_droite)
		"INV":
			perso.reparent(coulisse)
	
	# on affiche le personnage, affublé du bon sentiment
	perso.position = position_perso
	
	# on détermine l'émotiuon du perso et on affiche le sprite correcte
	if ligne_actuelle.sentiment != Personnage.EMOTIONS_PERSONNAGE.INVISIBLE:
		perso.sprite.texture = perso.portraits[ligne_actuelle.sentiment]
	else:
		perso.sprite.texture = null

func lire_dialogue(dialogue_lien: String = "test.dialogue", ligne: int = 0):
	# on commence par charger le dialogue à lire
	dialogue_actuel = _charger_dialogue(dialogue_lien)
	# on change la musique
	musique.stream = dialogue_actuel.musique_scène
	musique.play()
	# on change l'arrière plan
	sprite_arrière_plan.texture = dialogue_actuel.arrière_plan
	# on change la valeur du curseur
	dialogue_actuel.curseur = ligne
	# on commence le dialogue
	nouveau_dialogue_commencé.emit(dialogue_actuel)

# référence des fichiers dialogues
# le séparateur d'arguments est |
# LIGNE_REPLIQUE = <identifiant_personnage> <nom d'affichage> <sentiment> <réplique> <position>
# position = G|C|D|INV (gauche, centre ou droite ou invisible), centre assumé si rien et sentiment != invisible
# "FIN <dialogue suivant>" indique la fin du dialogue, le dialogue indiqué ensuite sera joué
# "QUESTION LIGNE_REPLIQUE <liste de réponses>", exemple:
# QUESTION N|Narrateur|invisible|Deez|INV nutz>dialogue1.dialogue ahahh>dialogue2.dialogue
# <liste de réponses> = <réplique> <dialogue déstination (intra/inter dialogue)>
# des informations concernant l'intégralité de la scène sont indiquées au début de la scène
# ces informations sont placés dans n'importe quel ordre et sont facultatives
# elles sont de la syntaxe suivante IDENTIFIANT <valeur>
# IDENTIFIANT peut etre MUSIQUE, FOND, ainsi que d'autres flags qui modifient la façon dont
# la scène fonctionne.
func _charger_dialogue(nom_dialogue: String = "test.dialogue") -> Scène:
	var fichier_dialogue = FileAccess.open("res://dialogues/" + nom_dialogue, FileAccess.READ)
	
	var texte_brut: String = fichier_dialogue.get_as_text()
	var liste_lignes_bruts = texte_brut.split("\n")
	
	var dialogue: Array = []
	
	var casting: Dictionary[String, Personnage] = {}
	
	# le numéro identifiant de la ligne
	var ligne_id: int = 0
	
	# la musique de la scène
	var musique_scène
	
	# l'image d'arrière plan de la scène
	var arrière_plan
	
	# on charge chaque ligne de dialogue
	for ligne: String in liste_lignes_bruts:
		# on incrémente l'id de la ligne
		# la liste des lignes commencent par 1
		ligne_id += 1
		
		# la ligne, tokénisée
		var ligne_tokénisée = ligne.split("|")
		
		# on gère les lignes spéciales, FIN, QUESTION, MUSIQUE, etc.
		if ligne.begins_with("FIN"):
			var destination: String = ligne.split(" ")[1]
			
			dialogue.append(
				Fin.new(destination)
			)
			
			continue
		elif ligne.begins_with("QUESTION"):
			var question_tokénisées = ligne.split("\t")
			
			print(question_tokénisées)
			
			var ligne_dialogue = question_tokénisées[1].split("|")
			
			var réponses = question_tokénisées.slice(2)
			var dict_réponses = {}
			
			for réponse in réponses:
				print(réponse)
				var temp_ré = réponse.split(">")
				dict_réponses[temp_ré[0]] = temp_ré[1]
			
			dialogue.append(
				Question.new(
					ligne_id,
					ligne_dialogue[0],
					ligne_dialogue[1],
					Personnage.string_to_émotions[ligne_dialogue[2]],
					ligne_dialogue[3],
					ligne_dialogue[4],
					dict_réponses
				)
			)
			
			continue
		# TODO
		if ligne.begins_with("MUSIQUE"):
			musique_scène = ligne.split(" ")[1]
			
			continue
		
		if ligne.begins_with("FOND"):
			arrière_plan = ligne.split(" ")[1]
			
			continue
		
		if ligne == "": # on passe les lignes vides
			continue
		
		# on trouve une référence au personnage en fonction de son identifiant
		var perso: Personnage = PersoGlobale.PERSONNAGES[ligne_tokénisée[0]]
			
		# si le personnage est pas encore dans le cast, on l'y ajoute
		if ligne_tokénisée[0] not in casting.keys():
			casting[ligne_tokénisée[0]] = perso
				
		if len(ligne_tokénisée) == 4: # la position sur la scène est indiquée
			dialogue.append(LigneDialogue.new(
				ligne_id,
				ligne_tokénisée[0],
				ligne_tokénisée[1],
				Personnage.string_to_émotions[ligne_tokénisée[2]],
				ligne_tokénisée[3],
				"INV"
			))
		else: # la position sur la scène n'est pas indiqué ou la ligne est autrement incomplète
			dialogue.append(LigneDialogue.new(
				ligne_id,
				ligne_tokénisée[0],
				ligne_tokénisée[1],
				Personnage.string_to_émotions[ligne_tokénisée[2]],
				ligne_tokénisée[3],
				ligne_tokénisée[4]
			))
	
	# TODO, ajouter musiqu et arrière plan
	var scène = Scène.new(nom_dialogue, casting, dialogue, musique_scène, arrière_plan)
	
	for i in scène.répliques:
		print(str(i))
	
	return scène

class Scène:
	# les différents types de ligne du script
	enum TYPE_LIGNES {
		DIALOGUE,
		FIN,
		QUESTION
	}
	
	# le fichier source de la scène
	var source: String
	
	# la musique qui se joue dans cette scène
	var musique_scène: AudioStream
	# l'arrière plan de la scène
	var arrière_plan: Texture2D
	
	# le dictionnaire qui associe tous les personnages de la scène à leur identifiant
	var cast: Dictionary[String, Personnage] = {}
	# la liste des répliques des personnages, dans l'ordre
	var répliques: Array
	# la position dans la scène, indique le numéor de la réplique
	var curseur: int = 0
	
	func _init(_source: String, _cast: Dictionary[String, Personnage], _répliques: Array, _musique: String, _fond: String):
		self.source = _source
		self.cast = _cast
		self.répliques = _répliques
		self.musique_scène = load("res://musiques/" + _musique)
		self.arrière_plan = load("res://fonds/" + _fond)
	
	func get_réplique(_curseur: int = self.curseur):
		return self.répliques[_curseur]

class LigneDialogue:
	var perso_id: String
	var nom_affichage: String
	var sentiment: Personnage.EMOTIONS_PERSONNAGE
	var réplique: String
	var position_scène: String
	var ligne_id: int
	
	func _init(_ligne_id:int, _perso_id: String, _nom_affichage: String, _sentiment: Personnage.EMOTIONS_PERSONNAGE, _réplique: String, _position_scène: String) -> void:
		self.perso_id = _perso_id
		self.nom_affichage = _nom_affichage
		self.sentiment = _sentiment
		self.réplique = _réplique
		self.position_scène = _position_scène
	
	func _to_string() -> String:
		return "["  + perso_id + "] " + nom_affichage + " : " + réplique + " (" + position_scène + ")"

class Fin:
	# la destination une fois que le dialogue est terminé
	# peut etre un autre dialogue, ou une ligne dans le dialogue en cours,
	# si la destination est dans le meme dialogue, la destination est le numéro de la ligne
	# ciblée, précédée d'un #
	var destination: String
	
	func _init(_destination: String) -> void:
		
		self.destination = _destination

class Question extends LigneDialogue:
	# la liste des réponses du joueur + la destionation de ces réponses
	# une réponse précédé d'un #, représente une ligne dans le meme dialogue
	# sinon, la destination représente un autre dialogue
	var réponses_destinations: Dictionary = {}
	
	func _init(_ligne_id:int, _perso_id: String, _nom_affichage: String, _sentiment: Personnage.EMOTIONS_PERSONNAGE, _réplique: String, _position_scène: String, _réponses_destination: Dictionary) -> void:
		super._init(_ligne_id, _perso_id, _nom_affichage, _sentiment, _réplique, _position_scène)
		
		réponses_destinations = _réponses_destination

# sauvegarder
func _on_bouton_sauvegarder_pressed() -> void:
	var fichier_sauvegarde = FileAccess.open("user://save.dat", FileAccess.WRITE)
	
	fichier_sauvegarde.store_line(Time.get_date_string_from_system() + ";" + dialogue_actuel.source + ";" + str(dialogue_actuel.curseur))

# écran de chargement de sauvegarde
func _on_bouton_charger_pressed() -> void:
	var écran = load("res://écran_parties_sauvegardées.tscn").instantiate()
	add_child(écran)

# on quitte le jeu
func _on_bouton_quitter_pressed() -> void:
	# on effectue une sauvegarde automatique
	_on_bouton_sauvegarder_pressed()
	
	# on envoie le signal de la fin de la partie
	GestionPartie.quitter.emit()
