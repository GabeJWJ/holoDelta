#Autoloaded script that contains the database
#Literally just to avoid making a connection for every single card and fuda
#Probably didn't break anything, but wasn't good

extends Node

var db : SQLite

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func _connect():
	db = SQLite.new()
	db.read_only = true
	db.path = "user://cardData.db"
	db.open_db()
