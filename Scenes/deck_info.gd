extends Control

var deck_info : Dictionary

signal pressed(deck_info)
signal delete_pressed


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if "oshi" in deck_info:
		var cardNumber = deck_info.oshi[0]
		var artNum = deck_info.oshi[1]
		
		%Front._initialize(cardNumber, artNum)
	
	if "deckName" in deck_info:
		%DeckName.text = deck_info.deckName



func _on_actual_button_mouse_entered() -> void:
	%OffBack.visible = false
	%FrontCover.visible = false

func _on_actual_button_mouse_exited() -> void:
	%OffBack.visible = true
	%FrontCover.visible = true

func _on_actual_button_pressed() -> void:
	emit_signal("pressed",deck_info)

func _on_delete_button_pressed() -> void:
	emit_signal("delete_pressed")
