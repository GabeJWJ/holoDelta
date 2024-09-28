extends Node2D
@onready var list = $ScrollContainer/VBoxContainer
@onready var loadButton = $ScrollContainer/VBoxContainer/Load
@onready var json = JSON.new()

signal selected(deckInfo)
signal cancel

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _clear_decks():
	for deckButton in list.get_children():
		if deckButton != loadButton:
			deckButton.queue_free()

func _all_decks():
	_clear_decks()
	var path = "user://Decks"
	var dir = DirAccess.open(path)
	if dir:
		for file_name in dir.get_files():
			if json.parse(FileAccess.get_file_as_string(path + "/" + file_name)) == 0:
				var deckButton = Button.new()
				deckButton.text = json.data.deckName
				deckButton.pressed.connect(_set_selected.bind(json.data))
				list.add_child(deckButton)
		list.move_child(loadButton,-1)
	else:
		print("An error occurred when trying to access the path.")


func _set_selected(deckInfo):
	emit_signal("selected",deckInfo)


func _on_load_dialog_file_selected(path):
	if json.parse(FileAccess.get_file_as_string(path)) == 0:
		emit_signal("selected",json.data)


func _on_load_pressed():
	$LoadDialog.visible = true


func _on_cancel_pressed():
	emit_signal("cancel")
