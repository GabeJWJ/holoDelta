extends Node

var settings = {}
@onready var json = JSON.new()
var languages = [["en","English"], ["ja","日本語"], ["es", "Español"]]
enum bloomCode {OK,Instant,Skip,No}
var version = "1.1.4.1"

var cardText = {}

@onready var sfx_bus_index = AudioServer.get_bus_index("SFX")
@onready var bgm_bus_index = AudioServer.get_bus_index("BGM")

# Called when the node enters the scene tree for the first time.
func _ready():
	if json.parse(FileAccess.get_file_as_string("user://settings.json")) == 0:
		settings = json.data
	
	if !settings.has("AllowUnrevealed"):
		settings["AllowUnrevealed"] = false
	
	if !settings.has("Language"):
		settings["Language"] = OS.get_locale_language()
	
	if !settings.has("SFXVolume"):
		settings["SFXVolume"] = 0
	
	if !settings.has("BGMVolume"):
		settings["BGMVolume"] = -5
	
	if !settings.has("AllowProxies"):
		settings["AllowProxies"] = false
	
	match settings.Language:
		"English":
			TranslationServer.set_locale("en")
			update_settings("Language", "en")
		"日本語":
			TranslationServer.set_locale("ja")
			update_settings("Language", "ja")
	
	locale()

func update_settings(key, value):
	if value == null:
		settings.erase(key)
	else:
		settings[key] = value
	var file_access = FileAccess.open("user://settings.json",FileAccess.WRITE)
	file_access.store_line(JSON.stringify(settings))
	file_access.close()
	locale()

func trans(key, overwrite=null):
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

func locale():
	TranslationServer.set_locale(settings.Language)

func get_language():
	for possible in languages:
		if possible[0] == settings.Language:
			return possible[1]

func _connect_local():
	for lang in languages:
		cardText[lang[0]] = load("user://cardLocalization/" + lang[0] + ".po") as Translation
