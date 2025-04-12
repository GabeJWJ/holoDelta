#The deck load menu used to pick a deck on main menu or load a deck in deck builder
#Looks through user/Decks for json files and creates a button for each
#Has a hard-coded "Load from file" button at the bottom

extends Node2D
@onready var list = $ScrollContainer/VBoxContainer
@onready var loadButton = $ScrollContainer/VBoxContainer/Load
@onready var json = JSON.new()

var file_access_web : FileAccessWeb

signal selected(deckInfo)
signal cancel

func _ready() -> void:
	if OS.has_feature("web"):
		file_access_web = FileAccessWeb.new()
		file_access_web.loaded.connect(_on_web_load_dialog_file_selected)

func _clear_decks() -> void:
	for deckButton in list.get_children():
		if deckButton != loadButton:
			deckButton.queue_free()

func _all_decks() -> void:
	_clear_decks()
	var path = "user://Decks"
	var dir = DirAccess.open(path)
	if dir:
		for file_name in dir.get_files():
			if json.parse(FileAccess.get_file_as_string(path + "/" + file_name)) == 0:
				var deckButton = Button.new()
				deckButton.auto_translate = false
				deckButton.text = json.data.deckName
				deckButton.pressed.connect(_set_selected.bind(json.data))
				list.add_child(deckButton)
		list.move_child(loadButton,-1) #Make sure the load button is on the bottom of the VBoxContainer
		$ScrollContainer.scroll_vertical = 0 #Reset the bar to the top
	else:
		print("An error occurred when trying to access the path.")


func _set_selected(deckInfo : Dictionary) -> void:
	var true_deck = {}
	if "deck" in deckInfo:
		true_deck["deck"] = deckInfo["deck"]
	if "cheerDeck" in deckInfo:
		true_deck["cheerDeck"] = deckInfo["cheerDeck"]
	if "oshi" in deckInfo:
		true_deck["oshi"] = deckInfo["oshi"]
	if "deckName" in deckInfo:
		true_deck["deckName"] = deckInfo["deckName"]
	
	emit_signal("selected",true_deck)


func _on_load_dialog_file_selected(path : String) -> void:
	if json.parse(FileAccess.get_file_as_string(path)) == 0:
		emit_signal("selected",json.data)

func _on_web_load_dialog_file_selected(file_name: String, type: String, base64_data: String) -> void:
	if json.parse(Marshalls.base64_to_utf8(base64_data)) == 0:
		emit_signal("selected",json.data)


func _on_load_pressed() -> void:
	if OS.has_feature("web"):
		file_access_web.open(".json")
	else:
		$LoadDialog.visible = true


func _on_cancel_pressed() -> void:
	emit_signal("cancel")
