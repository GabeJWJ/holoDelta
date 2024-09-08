extends Node

var settings
@onready var json = JSON.new()
var languages = ["English","日本語"]
enum bloomCode {OK,Instant,Skip,No}

var to_jp = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	if json.parse(FileAccess.get_file_as_string("user://settings.json")) == 0:
		settings = json.data
	else:
		settings = {"AllowUnrevealed":false,"Language":"English"}
	
	var database = SQLite.new()
	database.read_only = true
	if OS.has_feature("editor"):
		database.path = "res://cardData.db"
	else:
		database.path = OS.get_executable_path().get_base_dir() + "/cardData.db"
	database.open_db()
	
	var color_data = database.select_rows("colors","",["*"])
	var name_data = database.select_rows("holomemNames","",["*"])
	var supp_type_data = database.select_rows("supportTypes","",["*"])
	var tag_data = database.select_rows("tags","",["*"])
	
	for row in color_data:
		to_jp[row.colorName] = row.jpName
	for row in name_data:
		to_jp[row.name] = row.jpName
	for row in supp_type_data:
		to_jp[row.type] = row.jpName
	for row in tag_data:
		to_jp[row.tagName] = row.jpName
	
	locale()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func update_settings(key, value):
	settings[key] = value
	var file_access = FileAccess.open("user://settings.json",FileAccess.WRITE)
	file_access.store_line(JSON.stringify(settings))
	file_access.close()
	locale()

func en_or_jp(en_text,jp_text):
	match settings.Language:
		"English":
			return en_text
		"日本語":
			return jp_text
		_:
			return en_text

func locale():
	match settings.Language:
		"English":
			TranslationServer.set_locale("en")
		"日本語":
			TranslationServer.set_locale("ja")
