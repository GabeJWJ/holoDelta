extends Control

var cardFront
var notFound = false

func _initialize(cardNumber:String, artNum:int) -> void:
	var card_data = Database.cardData[cardNumber]
	
	if card_data.is_empty():
		notFound = true
		match Settings.settings.Language:
			"ja":
				cardFront = load("res://Sou_Desu_Ne_JP.png")
				%Front.texture = cardFront
			_:
				cardFront = load("res://Sou_Desu_Ne.png")
				%Front.texture = cardFront
	elif "ja" in card_data.cardArt[str(artNum)] and card_data.cardArt[str(artNum)].ja.unrevealed and !Settings.settings.AllowUnrevealed:
		notFound = true
		cardFront = load("res://spoilers.png")
		%Front.texture = cardFront
	
	var lang_code = "ja" if "ja" in card_data.cardArt[str(artNum)] else "en"
	if 'en' in card_data.cardArt[str(artNum)] and Settings.settings.OnlyEN:
		lang_code = 'en'
	else:
		for lang in card_data.cardArt[str(artNum)]:
			if Settings.settings.UseCardLanguage and lang == Settings.settings.Language and (Settings.settings.AllowProxies or !bool(card_data.cardArt[str(artNum)][lang].proxy)):
				lang_code = lang
	
	if cardNumber in Database.cardArts and int(artNum) in Database.cardArts[cardNumber] and lang_code in Database.cardArts[cardNumber][int(artNum)]:
		cardFront = load(Database.cardArts[cardNumber][int(artNum)][lang_code])
		%Front.texture = cardFront
	else:
		print(cardNumber, " ", artNum, " ", lang_code)


func _flip(back_image = null) -> void:
	if back_image:
		%Front.texture = back_image
	else:
		%Front.texture = cardFront
