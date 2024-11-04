extends Node2D

@export var zoneID:int
@onready var button = $ZoneButton
@export var rested = false

signal zone_clicked(zone_id)
signal zone_info_set(zone_id)
signal zone_info_clear


func showButton():
	button.visible = true

func hideButton():
	button.visible = false

func rest():
	if rested:
		pass
	else:
		rotation = 1.571
		position += Vector2(50,50)
		rested = true
		
func unrest():
	if !rested:
		pass
	else:
		rotation = 0
		position -= Vector2(50,50)
		rested = false

func _on_zone_button_pressed():
	emit_signal("zone_clicked",zoneID)


func _on_zone_button_mouse_entered():
	emit_signal("zone_info_set",zoneID)


func _on_zone_button_mouse_exited():
	emit_signal("zone_info_clear")
