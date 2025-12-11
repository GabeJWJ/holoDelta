#The deck load menu used to pick a deck on main menu or load a deck in deck builder
#Looks through user/Decks for json files and creates a button for each
#Has a hard-coded "Load from file" button at the bottom

extends Node2D
@onready var list = $ScrollContainer/VBoxContainer
@onready var loadButton = $ScrollContainer/VBoxContainer/Load
@onready var json = JSON.new()

var file_access_web : FileAccessWeb
const deckButtonClass = preload("res://Scenes/deck_info.tscn")

var file_to_delete = null

signal selected(deckInfo)
signal cancel

# Get called when the scene is instantiated
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
			if INTJSON.parse(FileAccess.get_file_as_string(path + "/" + file_name)) == 0:
				if Settings.settings.OnlyEN:
					var found_not_en = false
					if !check_if_card_is_en(INTJSON.data.oshi[0],INTJSON.data.oshi[1]):
						found_not_en = true
					for card_info in INTJSON.data.deck:
						if !check_if_card_is_en(card_info[0],card_info[2]):
							found_not_en = true
							break
					for card_info in INTJSON.data.cheerDeck:
						if !check_if_card_is_en(card_info[0],card_info[2]):
							found_not_en = true
							break
					if found_not_en:
						continue
				var deckButton = deckButtonClass.instantiate()
				deckButton.deck_info = INTJSON.data
				deckButton.pressed.connect(_set_selected)
				deckButton.delete_pressed.connect(_delete_deck.bind(INTJSON.data.deckName, file_name))
				list.add_child(deckButton)
		list.move_child(loadButton,-1) #Make sure the load button is on the bottom of the VBoxContainer
		$ScrollContainer.scroll_vertical = 0 #Reset the bar to the top
	else:
		print("An error occurred when trying to access the path.")

func check_if_card_is_en(cardNumber, artNum):
	return cardNumber in Database.cardData and str(artNum) in Database.cardData[cardNumber]["cardArt"] and \
		"en" in Database.cardData[cardNumber]["cardArt"][str(artNum)] and !Database.cardData[cardNumber]["cardArt"][str(artNum)]["en"]["proxy"]


func _set_selected(deckInfo : Dictionary) -> void:
	if !$Question.visible and !$LoadDialog.visible:
		emit_signal("selected",deckInfo)


func _on_load_dialog_file_selected(path : String) -> void:
	if !$Question.visible and INTJSON.parse(FileAccess.get_file_as_string(path)) == 0:
		emit_signal("selected",INTJSON.data)

func _on_web_load_dialog_file_selected(file_name: String, type: String, base64_data: String) -> void:
	if !$Question.visible and INTJSON.parse(Marshalls.base64_to_utf8(base64_data)) == 0:
		emit_signal("selected",INTJSON.data)


func _on_load_pressed() -> void:
	if !$Question.visible and !$LoadDialog.visible:
		if OS.has_feature("web"):
			file_access_web.open(".json")
		else:
			$LoadDialog.visible = true

func _delete_deck(deck_name: String, file_name: String) -> void:
	if !$Question.visible and !$LoadDialog.visible:
		file_to_delete = file_name
		$Question/Label.text = tr("DECK_DELETE_CONFIRM").format({"deckName":deck_name})
		$Question.visible = true

func _on_yes_pressed() -> void:
	if file_to_delete:
		DirAccess.remove_absolute("user://Decks/" + file_to_delete)
		_all_decks()
	_on_no_pressed()

func _on_no_pressed() -> void:
	file_to_delete = null
	$Question.visible = false

func _on_cancel_pressed() -> void:
	if !$Question.visible and !$LoadDialog.visible:
		emit_signal("cancel")


func _on_actual_button_mouse_entered() -> void:
	%OffBack.visible = false

func _on_actual_button_mouse_exited() -> void:
	%OffBack.visible = true
