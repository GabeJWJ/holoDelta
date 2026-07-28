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
var en_unreleased = {}

var unreleased_server = {}

var downloader
var needs_to_download_images = OS.has_feature("web")
var pathFront = "user://tempCardFronts/" if needs_to_download_images else "res://cardFronts/"
var webFront = "https://raw.githubusercontent.com/GabeJWJ/holoDelta/refs/heads/master/cardFronts/"

func setup_data(result, callback = null, progress = null):
	cardData = result
	totalCards = cardData.keys().size()
	var current = 0
	
	for cardNumber in cardData:
		var splitNumber = cardNumber.split("-",false,2)
		for art_code in cardData[cardNumber]["cardArt"]:
			for lang in cardData[cardNumber]["cardArt"][art_code]:
				var path = "{setcode}/{lang}/{number}/{artCode}.webp".format(
						{"setcode":splitNumber[0],"number":splitNumber[1],"lang":lang,"artCode":art_code})
				if !needs_to_download_images:
					path = pathFront + path
				if needs_to_download_images or ResourceLoader.exists(path):
					if cardNumber not in cardArts:
						cardArts[cardNumber] = {}
					if int(art_code) not in cardArts[cardNumber]:
						cardArts[cardNumber][int(art_code)] = {}
					if lang not in cardArts[cardNumber][int(art_code)]:
						#Was loading the texture, grabbing the image, and creating an ImageTexture from it
						#Not sure why; this has less juggling
						cardArts[cardNumber][int(art_code)][lang] = path
					else:
						print(path)
		current += 1
		if progress:
			progress.call(current, totalCards)
	if callback:
		callback.call()

func get_card_front(cardNumber:String, art_code:int, lang_code:String, callback:Callable) -> void:
	if needs_to_download_images:
		if cardNumber in cardArts and art_code in cardArts[cardNumber] and lang_code in cardArts[cardNumber][art_code]:
			var path = cardArts[cardNumber][art_code][lang_code]
			if FileAccess.file_exists(pathFront + path):
				#We already have this art downloaded - don't do it again
				callback.call()
			else:
				#We have to download it
				downloader.job(webFront + path).download(pathFront + path, callback)
		else:
			print(cardNumber, " ", art_code, " ", lang_code)
	else:
		#We have the images just stored in the executable. This should be checked before calling this function, but just in case.
		callback.call()

func delete_folder_recursive(path: String) -> void:
	if DirAccess.dir_exists_absolute(path):
		for dir in DirAccess.get_directories_at(path):
			delete_folder_recursive(path.path_join(dir))
		for file in DirAccess.get_files_at(path):
			DirAccess.remove_absolute(path.path_join(file))
		DirAccess.remove_absolute(path)
