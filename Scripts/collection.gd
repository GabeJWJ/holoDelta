extends Control

const card = preload("res://Scenes/card_info.tscn")
var all_cards = []
var cards = []
var current_card = 0

signal card_clicked(card_id)
signal card_right_clicked(card_id)
signal card_mouse_over(card_id)
signal card_mouse_left

func addCard(number, artCode):
	var newCard = card.instantiate()
	newCard.inEditor = true
	newCard.setup_info(number, artCode)
	if cards.size() > 0:
		newCard.visible = false
	$Cards.add_child(newCard)
	newCard.position = Vector2()
	cards.append(newCard)
	all_cards.append(newCard)
	newCard.scale = Vector2(0.27, 0.27)
	newCard.card_clicked.connect(on_card_clicked)
	newCard.card_right_clicked.connect(on_card_right_clicked)
	newCard.card_mouse_over.connect(on_card_mouse_over)
	newCard.card_mouse_left.connect(on_card_mouse_left)
	$NextAltArt.visible = false
	$LastAltArt.visible = false
	if cards.size() - current_card > 1:
		$NextAltArt.visible = true
	if current_card > 0:
		$LastAltArt.visible = true

func setAltArt(art_index):
	$NextAltArt.visible = false
	$LastAltArt.visible = false
	cards[current_card].visible = false
	cards[art_index].visible = true
	current_card = art_index
	if cards.size() - art_index > 1:
		$NextAltArt.visible = true
	if art_index > 0:
		$LastAltArt.visible = true

func changeAltArt(delta=1):
	var new_index = clamp(current_card + delta, 0, cards.size()-1)
	setAltArt(new_index)
	emit_signal("card_mouse_over",cards[current_card].cardID)

func on_card_clicked(card_id):
	emit_signal("card_clicked",card_id)
	pass

func on_card_right_clicked(card_id):
	emit_signal("card_right_clicked",card_id)

func on_card_mouse_over(card_id):
	emit_signal("card_mouse_over",card_id)

func on_card_mouse_left():
	emit_signal("card_mouse_left")

func oshi_filter(filter_list):
	var shown_card = cards[current_card] if current_card in cards else null
	var new_cards = []
	
	for potential_card in all_cards:
		var add_to_list = true
		if filter_list.Color != null:
			if !potential_card.is_color(filter_list.Color):
				add_to_list = false
		
		if filter_list.Name != null and !potential_card.has_name(filter_list.Name):
			add_to_list = false
		
		if filter_list.Life != null and potential_card.life != filter_list.Life:
			add_to_list = false
	
		if filter_list.Setcode != null and potential_card.cardNumber.split("-")[0] != filter_list.Setcode:
			add_to_list = false
		
		if filter_list.Search != "" and !potential_card.fullText.to_lower().contains(filter_list.Search.to_lower()):
			add_to_list = false
		
		if add_to_list:
			new_cards.append(potential_card)
		else:
			potential_card.visible = false
	cards = new_cards
	current_card = 0
	if shown_card in cards:
		setAltArt(cards.find(shown_card))
	elif cards.size() > 0:
		setAltArt(0)
		
