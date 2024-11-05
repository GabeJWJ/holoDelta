extends Node

var settings
@onready var json = JSON.new()
var languages = [["en","English"], ["ja","日本語"]]
enum bloomCode {OK,Instant,Skip,No}
var version = "1.1.3"

var cardText = {}

@onready var sfx_bus_index = AudioServer.get_bus_index("SFX")

# Called when the node enters the scene tree for the first time.
func _ready():
	if json.parse(FileAccess.get_file_as_string("user://settings.json")) == 0:
		settings = json.data
	else:
		settings = {"AllowUnrevealed":false,"Language":OS.get_locale_language()}
	
	if !settings.has("SFXVolume"):
		settings["SFXVolume"] = 0
	
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

func trans(key):
	var result = cardText[settings.Language].get_message(key)
	if result == "":
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
