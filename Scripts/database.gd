extends Node

var db : SQLite

# Called when the node enters the scene tree for the first time.
func _ready():
	db = SQLite.new()
	db.read_only = true
	if OS.has_feature("editor"):
		db.path = "res://cardData.db"
	else:
		db.path = OS.get_executable_path().get_base_dir() + "/cardData.db"
	db.open_db()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
