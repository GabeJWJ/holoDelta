#It's a 6-sided die.

extends Node3D

var currentNumber = 5
@export var is_your_die = false

signal rolled

func roll(result: int) -> void:
	#Rolls the die, including animation
	#Doesn't return the result, instead emits a signal to side with the result
	
	currentNumber = result
	
	#Hard-coded determination of how it should rotate to show the correct value face-up
	var rotx = 0
	var rotz = 0
	match currentNumber:
		1:
			rotz = 1.571
		2:
			rotx = 3.141
		3:
			rotx = 1.571
		4:
			rotx = 4.712
		6:
			rotz = 4.712
	
	#Roll animation is tween to random rotation then to the new one very quick
	#y rotation is random to allow some variability in how the die lands
	var tween = get_tree().create_tween()
	tween.tween_property(self,"rotation",Vector3(randf_range(-3.141,3.141),randf_range(-3.141,3.141),randf_range(-3.141,3.141)),0.1)
	tween.tween_property(self,"rotation",Vector3(rotx, randf_range(-3.141,3.141), rotz),0.1)

func _on_static_body_3d_input_event(_camera, event, _position, _normal, _shape_idx) -> void:
	#Fires when the static body 3d (a bounding rectangle for the die) is clicked
	#Only worry about event, which gets immediately cast to an InputEventMouseButton
	
	var mouse_click = event as InputEventMouseButton
	if mouse_click and mouse_click.button_index == 1 and mouse_click.pressed and is_your_die:
		emit_signal("rolled")

func new_texture(image):
	#Set the texture of the die - used for cosmetics
	#image : Image - the texture to set the die to
	
	var newMaterial = StandardMaterial3D.new()
	newMaterial.albedo_texture = ImageTexture.create_from_image(image)
	$dice/Cube.set_surface_override_material(0,newMaterial)
