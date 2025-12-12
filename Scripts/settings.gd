#Autoloaded script for global settings.
#Settings are locally stored in a dictionary, saved to settings.json in user folder
#
#I don't know where to mention this, so might as well here
#Translations are split up into two different files
#The main game text is stored internally - in the Localization folder in resources
#The card text is stored externally for the same reason the cardData.db is
#	so we can add new cards without recompiling the whole game
#So at runtime, we look for po files in user/cardLocalization and load them as Translation objects

extends Node

var settings = {}
@onready var json = JSON.new()
var languages = {"en":"English", "ja":"日本語", "ko":"한글", "es": "Español", "fr":"Français", "vi":"Tiếng Việt", "zh_TW":"繁體中文"} #Contains both the locale code and the user-friendly text for buttons
enum bloomCode {OK,Instant,Skip,No} #OK - can bloom normally, Instant - can bloom on something played this turn, Skip - can bloom a 2nd on debut, No - can't bloom
var client_version = FileAccess.get_file_as_string("res://client_version.txt")
var card_version = "Not Found"

var cardText = {}

#Needed for audio sliders to modify the channel volumes
@onready var sfx_bus_index = AudioServer.get_bus_index("SFX")
@onready var bgm_bus_index = AudioServer.get_bus_index("BGM")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("Client Version: ", client_version)
	#Try to load settings from file
	if INTJSON.parse(FileAccess.get_file_as_string("user://settings.json")) == 0:
		settings = INTJSON.data
	
	#We set each default value individually in case someone's updating from an old version
	#They'd have some values saved, but not all
	if !settings.has("AllowUnrevealed"):
		settings["AllowUnrevealed"] = false
	
	if !settings.has("Language"):
		settings["Language"] = OS.get_locale_language()
	
	#There was a change in 1.1.3 from storing the language as the user-friendly name to
	#	storing the locale code
	#This will fix that
	match settings.Language:
		"English":
			TranslationServer.set_locale("en")
			update_settings("Language", "en")
		"日本語":
			TranslationServer.set_locale("ja")
			update_settings("Language", "ja")
	
	#Just a clean reset to default if not found
	if settings["Language"] not in languages:
		update_settings("Language", "en")
	
	if !settings.has("SFXVolume"):
		settings["SFXVolume"] = 0
	
	if !settings.has("BGMVolume"):
		settings["BGMVolume"] = -5
	
	if !settings.has("AllowProxies"):
		settings["AllowProxies"] = false
	
	if !settings.has("UseCardLanguage"):
		settings["UseCardLanguage"] = settings["AllowProxies"]
	
	if !settings.has("OnlyEN"):
		settings["OnlyEN"] = false
	
	if !settings.has("Name"):
		settings["Name"] = ""
	
	if !settings.has("LoadedDecks"):
		settings["LoadedDecks"] = []
	
	locale()

func update_settings(key, value) -> void:
	#Call to update a setting and automatically save it
	#IF VALUE IS NULL, ERASES THE SETTING
	#key : any (probably string) - the setting to change
	#value : any (easy ones please) - what to change the setting to
	
	if value == null: #Allows erasing a setting. Unsure off the top of my head if I ever use this
		settings.erase(key)
	else:
		settings[key] = value
	var file_access = FileAccess.open("user://settings.json",FileAccess.WRITE)
	file_access.store_line(JSON.stringify(settings))
	file_access.close()
	locale()

func trans(key : String, overwrite=null) -> String:
	#Returns the translation for the key in the cardLocalization po files
	#Automatically returns it for the correct language chosen, but can be overwritten
	#If not found, falls back to en, then ja, then returns the key itself
	#key : String - the key to translate. Anything specific to a card, and other constants found in db
	#overwrite : String (locale code) - the language you want it translated in. Don't use carelessly
	
	var result = cardText[settings.Language if overwrite == null else overwrite].get_message(key)
	if result == "":
		if overwrite == null:
			if settings.Language not in ["en", "ja"]:
				return trans(key, "en")
			elif settings.Language != "ja":
				return trans(key, "ja")
		return key
	else:
		return result

func locale() -> void:
	#Sets the locale correctly. Not sure if needed, but isn't hurting anything.
	
	TranslationServer.set_locale(settings.Language)

func get_language() -> String :
	#Returns the user-friendly name of the current language
	
	if settings.Language in languages:
		return languages[settings.Language]
	
	return "???"

func _connect_local(callback = null) -> void:
	#Sets up the cardLocalization po files for use with trans()
	
	for lang in languages:
		cardText[lang] = load("res://cardLocalization/" + lang + ".po") as Translation
	
	if callback:
		callback.call()
