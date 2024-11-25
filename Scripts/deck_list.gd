#The deck load menu used to pick a deck on main menu or load a deck in deck builder
#Looks through user/Decks for json files and creates a button for each
#Has a hard-coded "Load from file" button at the bottom

extends Node2D
@onready var list = $ScrollContainer/VBoxContainer
@onready var loadButton = $ScrollContainer/VBoxContainer/Load
@onready var json = JSON.new()

signal selected(deckInfo)
signal cancel

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
	emit_signal("selected",deckInfo)


func _on_load_dialog_file_selected(path : String) -> void:
	if json.parse(FileAccess.get_file_as_string(path)) == 0:
		emit_signal("selected",json.data)


func _on_load_pressed() -> void:
	$LoadDialog.visible = true


func _on_cancel_pressed() -> void:
	emit_signal("cancel")
