#Autoloaded script that contains the database
#Literally just to avoid making a connection for every single card and fuda
#Probably didn't break anything, but wasn't good

extends Node


var db
var cardData = {}
var totalCards = 0
var cardArts = {}
var setup = false

var current_banlist = {}
var en_current_banlist = {}
var unreleased = {}

func setup_data(result, callback = null, progress = null):
	cardData = result
	totalCards = cardData.keys().size()
	var current = 0
	
	for cardNumber in cardData:
		var splitNumber = cardNumber.split("-",false,2)
		for art_code in cardData[cardNumber]["cardArt"]:
			for lang in cardData[cardNumber]["cardArt"][art_code]:
				var path = "res://cardFronts/{setcode}/{lang}/{number}/{artCode}.webp".format(
					{"setcode":splitNumber[0],"number":splitNumber[1],"lang":lang,"artCode":art_code})
				if ResourceLoader.exists(path):
					if cardNumber not in cardArts:
						cardArts[cardNumber] = {}
					if int(art_code) not in cardArts[cardNumber]:
						cardArts[cardNumber][int(art_code)] = {}
					if lang not in cardArts[cardNumber][int(art_code)]:
						var image = load(path).get_image()
						image.resize(309,429)
						cardArts[cardNumber][int(art_code)][lang] = ImageTexture.create_from_image(image)
				else:
					print(path)
		current += 1
		if progress:
			progress.call(current, totalCards)
	if callback:
		callback.call()
