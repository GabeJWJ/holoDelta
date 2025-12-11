#The zones that holomems can be. Mainly just provides those yellow buttons when selecting a
#	zone or holomem.
#I've tried to make it do other things, but I have no idea how much of this ever got used

extends Node2D

@export var zoneID:int
@onready var button = $ZoneButton
@export var rested = false

var current_damage := 0
var damage_this_turn := 0
var notes_this_turn := []
var damage_history := []
var goldfish_mode := false

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


func add_damage(value : int) -> void:
	current_damage += value
	damage_this_turn += value
	if current_damage < 0:
		current_damage = 0
	elif current_damage > 990:
		current_damage = 990
	%ZoneDamage.text = str(current_damage)

func lock_in_damage() -> void:
	damage_history.append([current_damage, damage_this_turn, ", ".join(notes_this_turn)])
	damage_this_turn = 0
	notes_this_turn = []
	%ZoneButton.tooltip_text = _get_damage_history()

func _get_damage_history() -> String:
	var result = ""
	for result_row in damage_history:
		result += ("%d\t (%d)\t %s" % result_row) + "\n"
	return result

func show_damage() -> void:
	goldfish_mode = true
	%ZoneDamage.visible = true
	%ZoneButton.visible = true

func add_note(new_note: String) -> void:
	notes_this_turn.append(new_note)
