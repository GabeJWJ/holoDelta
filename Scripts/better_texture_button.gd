#The "LookAt" menu can't contain the card objects - that would be a nightmare
#But just using TextureButtons would require more shenanigans to get the nice
# "darkening on hover" effect, so I made this

extends Node2D

@export var id:int

var filter_info = {"holomem" : false, "holomem_level" : null, "holomem_color" : null, "holomem_name" : null, "holomem_tag" : [], "holomem_extra" : null,
						"support" : false, "support_type" : null, "support_tag" : [],
						"cheer" : false, "cheer_color" : null }

signal pressed
signal mouse_entered
signal mouse_exited


func _on_texture_button_pressed():
	emit_signal("pressed")


func _on_texture_button_mouse_entered():
	emit_signal("mouse_entered")


func _on_texture_button_mouse_exited():
	emit_signal("mouse_exited")

func set_art(cardNumber: String, artNum: int) -> void:
	$CardFront._initialize(cardNumber, artNum)
