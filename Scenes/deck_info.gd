extends Control

var deck_info : Dictionary

signal pressed(deck_info)
signal delete_pressed


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if "oshi" in deck_info:
		var cardNumber = deck_info.oshi[0]
		var artNum = deck_info.oshi[1]
		
		var card_data = Database.cardData[cardNumber]
	
		if card_data.is_empty():
			match Settings.settings.Language:
				"ja":
					%Front.texture = load("res://Sou_Desu_Ne_JP.png")
				_:
					%Front.texture = load("res://Sou_Desu_Ne.png")
		elif card_data.cardArt[str(artNum)].ja.unrevealed and !Settings.settings.AllowUnrevealed:
			%Front.texture = load("res://spoilers.png")
		
		#IF YOU CHANGE THIS CODE ALSO CHANGE IT IN CARD
		var lang_code = "ja" if "ja" in card_data.cardArt[str(artNum)] else "en"
		if 'en' in card_data.cardArt[str(artNum)] and Settings.settings.OnlyEN:
			lang_code = 'en'
		else:
			for lang in card_data.cardArt[str(artNum)]:
				if Settings.settings.UseCardLanguage and lang == Settings.settings.Language and (Settings.settings.AllowProxies or !bool(card_data.cardArt[str(artNum)][lang].proxy)):
					lang_code = lang
		
		if cardNumber in Database.cardArts and int(artNum) in Database.cardArts[cardNumber] and lang_code in Database.cardArts[cardNumber][int(artNum)]:
			%Front.texture = Database.cardArts[cardNumber][int(artNum)][lang_code]
		else:
			print(cardNumber, " ", artNum, " ", lang_code)
		#YES I SHOULDN'T JUST COPY-PASTE CODE - THIS ONE WAS TRICKY TO SEPARATE INTO ITS OWN THING
	
	if "deckName" in deck_info:
		%DeckName.text = deck_info.deckName



func _on_actual_button_mouse_entered() -> void:
	%OffBack.visible = false
	%FrontCover.visible = false

func _on_actual_button_mouse_exited() -> void:
	%OffBack.visible = true
	%FrontCover.visible = true

func _on_actual_button_pressed() -> void:
	emit_signal("pressed",deck_info)

func _on_delete_button_pressed() -> void:
	emit_signal("delete_pressed")
