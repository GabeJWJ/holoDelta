extends Node2D

var database

const card = preload("res://Scenes/card.tscn")
var all_cards = []
var in_deck_dictionary = {}
var total_main = 0
var total_cheer = 0
var json = JSON.new()

@onready var oshi_tab = $CanvasLayer/PossibleCards/Oshi/ColorRect
@onready var main_tab = $"CanvasLayer/PossibleCards/Main Deck/ColorRect"
@onready var cheer_tab = $CanvasLayer/PossibleCards/Cheer/ColorRect
@onready var main_deck = $CanvasLayer/YourDeck/MainDeck/ColorRect
@onready var cheer_deck = $CanvasLayer/YourDeck/CheerDeck/ColorRect
@onready var main_count = $CanvasLayer/YourDeck/MainCount
@onready var cheer_count = $CanvasLayer/YourDeck/CheerCount
var oshiCard

# Called when the node enters the scene tree for the first time.
func _ready():
	var path
	if !OS.has_feature("editor"):
		path = OS.get_executable_path().get_base_dir() + "/Decks"
	else:
		path = "res://Decks"
	
	
	database = SQLite.new()
	database.read_only = true
	database.path = "res://cardData.db"
	database.open_db()
	
	var art_data = database.select_rows("cardHasArt","",["cardID","art_index"])
	
	art_data.sort_custom(custom_art_row_sort)
	
	for art_row in art_data:
		var cardNumber = art_row.cardID
		var artCode = art_row.art_index
		var newCardButton = create_card_button(cardNumber,artCode)
		if newCardButton.cardType == "Oshi":
			oshi_tab.add_child(newCardButton)
		elif newCardButton.cardType == "Cheer":
			cheer_tab.add_child(newCardButton)
		else:
			main_tab.add_child(newCardButton)
		
		var index = newCardButton.get_index()
		newCardButton.scale = Vector2(0.6,0.6)
		newCardButton.position = Vector2(100 + 200*(index % 3), 150 + 280*(index / 3))
		newCardButton.card_clicked.connect(_on_menu_card_clicked)
		newCardButton.card_right_clicked.connect(_on_menu_card_right_clicked)
	
	oshi_tab.custom_minimum_size = Vector2(0, (oshi_tab.get_child_count() / 3)*280 + 300)
	main_tab.custom_minimum_size = Vector2(0, (main_tab.get_child_count()/3)*280 + 300)
	cheer_tab.custom_minimum_size = Vector2(0, (cheer_tab.get_child_count()/3)*280 + 300)
	
	$CanvasLayer/SaveDeck.disabled = !is_deck_legal()

func custom_art_row_sort(a,b):
	if a.cardID < b.cardID:
		return true
	elif a.cardID == b.cardID and a.art_index < b.art_index:
		return true
	else:
		return false

func load_from_deck_info(deck_info):
	in_deck_dictionary = {}
	total_cheer = 0
	total_main = 0
	for cB in main_deck.get_children():
		cB.name = "PleaseDelete"
		cB.queue_free()
	for cB in cheer_deck.get_children():
		cB.name = "PleaseDelete"
		cB.queue_free()
	
	if oshiCard == null:
		oshiCard = create_card_button(deck_info.oshi[0],deck_info.oshi[1])
		oshiCard.position = Vector2(460,750)
		oshiCard.scale = Vector2(0.65,0.65)
		$CanvasLayer.add_child(oshiCard)
	else:
		oshiCard.setup_info(deck_info.oshi[0],database,deck_info.oshi[1])
	
	for card_info in deck_info.deck:
		var newCardButton = create_card_button(card_info[0],card_info[2])
		newCardButton.scale = Vector2(0.5,0.5)
		newCardButton.update_amount(card_info[1])
		total_main += card_info[1]
		newCardButton.set_amount_hidden(true)
		main_deck.add_child(newCardButton)
		newCardButton.card_clicked.connect(_on_deck_card_clicked)
		if in_deck_dictionary.has(card_info[0]):
			in_deck_dictionary[card_info[0]] += card_info[1]
		else:
			in_deck_dictionary[card_info[0]] = card_info[1]
	
	for card_info in deck_info.cheerDeck:
		var newCardButton = create_card_button(card_info[0],card_info[2])
		newCardButton.scale = Vector2(0.55,0.55)
		newCardButton.update_amount(card_info[1])
		total_cheer += card_info[1]
		newCardButton.set_amount_hidden(true)
		cheer_deck.add_child(newCardButton)
		newCardButton.card_clicked.connect(_on_deck_card_clicked)
		if in_deck_dictionary.has(card_info[0]):
			in_deck_dictionary[card_info[0]] += card_info[1]
		else:
			in_deck_dictionary[card_info[0]] = card_info[1]
	
	update_main_deck_children()
	update_cheer_deck_children()
	
	main_count.text = str(total_main) + "/50"
	cheer_count.text = str(total_cheer) + "/20"
	$CanvasLayer/DeckName.text = deck_info.deckName
	
	$CanvasLayer/SaveDeck.disabled = !is_deck_legal()

func create_card_button(number,art_code):
	var new_id = all_cards.size()
	var newCard = card.instantiate()
	newCard.name = "Card" + str(new_id)
	newCard.setup_info(number,database,art_code)
	newCard.cardID = new_id
	
	#newCard.card_clicked.connect(_on_card_clicked)
	newCard.card_mouse_over.connect(update_info)
	newCard.card_mouse_left.connect(clear_info)
	all_cards.append(newCard)
	return newCard

func _on_menu_card_clicked(card_id):
	if $CanvasLayer/LoadDialog.visible or $CanvasLayer/SaveDialog.visible:
		return
	
	var actualCard = all_cards[card_id]
	match actualCard.cardType:
		"Oshi":
			if oshiCard == null:
				oshiCard = create_card_button(actualCard.cardNumber,actualCard.artNum)
				oshiCard.position = Vector2(460,750)
				oshiCard.scale = Vector2(0.65,0.65)
				$CanvasLayer.add_child(oshiCard)
			else:
				oshiCard.setup_info(actualCard.cardNumber,database,actualCard.artNum)
			#deck_info.oshi = [actualCard.cardNumber,actualCard.artNum]
		"Cheer":
			var alreadyHere = find_in_deck_with_number(actualCard.cardNumber,actualCard.artNum,cheer_deck)
			if alreadyHere == null:
				var newCardButton = create_card_button(actualCard.cardNumber,actualCard.artNum)
				newCardButton.scale = Vector2(0.55,0.55)
				newCardButton.set_amount_hidden(true)
				cheer_deck.add_child(newCardButton)
				in_deck_dictionary[actualCard.cardNumber] = 1
				newCardButton.update_amount(1)
				var index = newCardButton.get_index()
				newCardButton.position = Vector2(100 + 190*index, 150)
				newCardButton.card_clicked.connect(_on_deck_card_clicked)
			else:
				alreadyHere.set_amount_hidden(true)
				alreadyHere.update_amount(alreadyHere.get_amount()+1)
				in_deck_dictionary[actualCard.cardNumber] += 1
				#deck_info.cheerDeck
			total_cheer += 1
			cheer_deck.custom_minimum_size = Vector2(cheer_deck.get_child_count()*380 + 200, 0)
		_:
			var alreadyHere = find_in_deck_with_number(actualCard.cardNumber,actualCard.artNum,main_deck)
			if alreadyHere == null:
				var newCardButton = create_card_button(actualCard.cardNumber,actualCard.artNum)
				newCardButton.scale = Vector2(0.5,0.5)
				newCardButton.set_amount_hidden(true)
				main_deck.add_child(newCardButton)
				in_deck_dictionary[actualCard.cardNumber] = 1
				newCardButton.update_amount(1)
				var index = newCardButton.get_index()
				newCardButton.position = Vector2(100 + 170*(index % 5), 130 + 240*(index / 5))
				newCardButton.card_clicked.connect(_on_deck_card_clicked)
			else:
				alreadyHere.set_amount_hidden(true)
				alreadyHere.update_amount(alreadyHere.get_amount()+1)
				in_deck_dictionary[actualCard.cardNumber] += 1
				#deck_info.deck
			total_main += 1
			main_deck.custom_minimum_size = Vector2(0, (main_deck.get_child_count() / 5)*240 + 260)
	
	main_count.text = str(total_main) + "/50"
	cheer_count.text = str(total_cheer) + "/20"
	
	$CanvasLayer/SaveDeck.disabled = !is_deck_legal()

func _on_menu_card_right_clicked(card_id):
	if $CanvasLayer/LoadDialog.visible or $CanvasLayer/SaveDialog.visible:
		return
	
	var actualCard = all_cards[card_id]
	if actualCard.cardType == "Oshi":
		return
	var alreadyHere
	if actualCard.cardType == "Cheer":
		alreadyHere = find_in_deck_with_number(actualCard.cardNumber,actualCard.artNum,cheer_deck)
		if alreadyHere != null:
			alreadyHere.set_amount_hidden(true)
			alreadyHere.update_amount(alreadyHere.get_amount()-1)
			in_deck_dictionary[actualCard.cardNumber] -= 1
			#deck_info.cheerDeck
		total_cheer -= 1
	else:
		alreadyHere = find_in_deck_with_number(actualCard.cardNumber,actualCard.artNum,main_deck)
		if alreadyHere != null:
			alreadyHere.set_amount_hidden(true)
			alreadyHere.update_amount(alreadyHere.get_amount()-1)
			in_deck_dictionary[actualCard.cardNumber] -= 1
			#deck_info.cheerDeck
		total_main -= 1
	
	if alreadyHere != null and in_deck_dictionary[actualCard.cardNumber] == 0:
		in_deck_dictionary.erase(actualCard.cardNumber)
		alreadyHere.name = "PleaseDelete"
		alreadyHere.queue_free()
		update_main_deck_children()
		update_cheer_deck_children()
	
	$CanvasLayer/SaveDeck.disabled = !is_deck_legal()

func _on_deck_card_clicked(card_id):
	if $CanvasLayer/LoadDialog.visible or $CanvasLayer/SaveDialog.visible:
		return
	
	var actualCard = all_cards[card_id]
	actualCard.update_amount(actualCard.get_amount()-1)
	in_deck_dictionary[actualCard.cardNumber] -= 1
	if actualCard.cardType == "Cheer":
		total_cheer -= 1
	else:
		total_main -= 1
	if in_deck_dictionary[actualCard.cardNumber] == 0:
		in_deck_dictionary.erase(actualCard.cardNumber)
		actualCard.name = "PleaseDelete"
		actualCard.queue_free()
		update_main_deck_children()
		update_cheer_deck_children()
	main_count.text = str(total_main) + "/50"
	cheer_count.text = str(total_cheer) + "/20"
	
	$CanvasLayer/SaveDeck.disabled = !is_deck_legal()

func find_in_deck_with_number(cardNumber,artNum,areaToCheck):
	for cardButton in areaToCheck.get_children():
		if cardButton.cardNumber == cardNumber and artNum == cardButton.artNum:
			return cardButton

func is_deck_legal():
	$CanvasLayer/Problems/ProblemList.text = ""
	
	if oshiCard == null:
		$CanvasLayer/Problems/ProblemList.text += "No oshi selected\n"
	
	if total_main < 50:
		$CanvasLayer/Problems/ProblemList.text += "Too few cards in main deck\n"
	elif total_main > 50:
		$CanvasLayer/Problems/ProblemList.text += "Too many cards in main deck\n"
	if total_cheer < 20:
		$CanvasLayer/Problems/ProblemList.text += "Too few cards in cheer deck\n"
	elif total_cheer > 20:
		$CanvasLayer/Problems/ProblemList.text += "Too many cards in cheer deck\n"
	
	var found_debut = false
	var too_many_copies = false
	for cardButton in main_deck.get_children():
		if cardButton.cardType == "Holomem" and cardButton.level == 0 and !cardButton.name.contains("PleaseDelete"):
			found_debut = true
	if !found_debut:
		$CanvasLayer/Problems/ProblemList.text += "No debut holomems\n"
	
	for cardNumber in in_deck_dictionary:
		var data = database.select_rows("mainCards","cardID LIKE '" + cardNumber + "'", ["*"])[0]
		if data.cardLimit != -1 and in_deck_dictionary[cardNumber] > data.cardLimit:
			too_many_copies = true
			$CanvasLayer/Problems/ProblemList.text += "Too many copies of " + cardNumber + "\n"
	
	return total_main == 50 and total_cheer == 20 and oshiCard != null and found_debut and !too_many_copies

func update_main_deck_children():
	var index = 0
	for cardButton in main_deck.get_children():
		if cardButton.name.contains("PleaseDelete"):
			continue
		cardButton.position = Vector2(100 + 170*(index % 5), 130 + 240*(index / 5))
		index += 1
	main_deck.custom_minimum_size = Vector2(0, (main_deck.get_child_count() / 5)*240 + 260)

func update_cheer_deck_children():
	var index = 0
	for cardButton in cheer_deck.get_children():
		if cardButton.name.contains("PleaseDelete"):
			continue
		cardButton.position = Vector2(100 + 190*index, 150)
		index += 1
	cheer_deck.custom_minimum_size = Vector2(cheer_deck.get_child_count()*380 + 200, 0)

func update_info(card_id):
	$CanvasLayer/Info/Preview.texture = all_cards[card_id].cardFront
	$CanvasLayer/Info/CardText.text = all_cards[card_id].full_desc()

func clear_info():
	$CanvasLayer/Info/Preview.texture = load("res://cardbutton.png")
	$CanvasLayer/Info/CardText.text = ""


func _on_load_deck_pressed():
	$CanvasLayer/LoadDialog.visible = true


func _on_load_dialog_file_selected(path):
	if json.parse(FileAccess.get_file_as_string(path)) == 0:
		load_from_deck_info(json.data)


func _on_save_deck_pressed():
	$CanvasLayer/SaveDialog.visible = true


func _on_save_dialog_file_selected(path):
	if !path.ends_with(".json"):
		path += ".json"
	
	var deck_info = {}
	
	if $CanvasLayer/DeckName.text == "":
		deck_info.deckName = $CanvasLayer/DeckName.placeholder_text
	else:
		deck_info.deckName = $CanvasLayer/DeckName.text
	
	deck_info.oshi = [oshiCard.cardNumber,oshiCard.artNum]
	
	deck_info.deck = []
	deck_info.cheerDeck = []
	
	for cB in main_deck.get_children():
		deck_info.deck.append([cB.cardNumber,cB.get_amount(),cB.artNum])
	
	for cB in cheer_deck.get_children():
		deck_info.cheerDeck.append([cB.cardNumber,cB.get_amount(),cB.artNum])
	
	var json_string := JSON.stringify(deck_info)
	# We will need to open/create a new file for this data string
	var file_access := FileAccess.open(path, FileAccess.WRITE)
	if not file_access:
		print("An error happened while saving data: ", FileAccess.get_open_error())
		return

	file_access.store_line(json_string)
	file_access.close()


func _on_main_menu_pressed():
	get_tree().change_scene_to_file("res://Scenes/board.tscn")


func _on_clear_pressed():
	in_deck_dictionary = {}
	total_cheer = 0
	total_main = 0
	for cB in main_deck.get_children():
		cB.name = "PleaseDelete"
		cB.queue_free()
	for cB in cheer_deck.get_children():
		cB.name = "PleaseDelete"
		cB.queue_free()
	oshiCard.queue_free()
	
	update_main_deck_children()
	update_cheer_deck_children()
	
	$CanvasLayer/SaveDeck.disabled = !is_deck_legal()
