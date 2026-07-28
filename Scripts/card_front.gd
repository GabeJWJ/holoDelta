extends Control

var cardFront
var cardFrontPath
var cardFrontLoading = false
var notFound = false

var cardArtInfo

func _initialize(cardNumber:String, artNum:int, load_art:bool=true) -> void:
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
		cardFrontPath = Database.cardArts[cardNumber][int(artNum)][lang_code]
		cardArtInfo = [cardNumber, int(artNum), lang_code]
		if Database.needs_to_download_images:
			cardFrontPath = Database.pathFront + cardFrontPath
		if load_art:
			_start_loading_art()
	else:
		print(cardNumber, " ", artNum, " ", lang_code)

func _start_loading_art() -> void:
	if cardFrontPath:
		if Database.needs_to_download_images:
			Database.get_card_front(cardArtInfo[0], cardArtInfo[1], cardArtInfo[2], _load_art_web)
		else:
			ResourceLoader.load_threaded_request(cardFrontPath)
			cardFrontLoading = true

func _load_art_web(_response=null) -> void:
	if Database.needs_to_download_images and cardFrontPath and FileAccess.file_exists(cardFrontPath):
		var image = Image.load_from_file(cardFrontPath)
		if image:
			cardFront = ImageTexture.create_from_image(image)
			%Front.texture = cardFront
		else:
			match Settings.settings.Language:
				"ja":
					cardFront = load("res://Sou_Desu_Ne_JP.png")
					%Front.texture = cardFront
				_:
					cardFront = load("res://Sou_Desu_Ne.png")
					%Front.texture = cardFront

func _process(_delta: float) -> void:
	if cardFrontLoading and ResourceLoader.load_threaded_get_status(cardFrontPath) == 3:
		cardFront = ResourceLoader.load_threaded_get(cardFrontPath)
		%Front.texture = cardFront
		cardFrontLoading = false


func _flip(back_image = null) -> void:
	if back_image:
		%Front.texture = back_image
	else:
		%Front.texture = cardFront
