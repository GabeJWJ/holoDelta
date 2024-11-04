extends Node3D

var currentNumber = 5

signal die_result(num)

func roll():
	currentNumber = randi_range(1,6)
	
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
	
	var tween = get_tree().create_tween()
	tween.tween_property(self,"rotation",Vector3(randf_range(-3.141,3.141),randf_range(-3.141,3.141),randf_range(-3.141,3.141)),0.1)
	tween.tween_property(self,"rotation",Vector3(rotx, randf_range(-3.141,3.141), rotz),0.1)
	
	emit_signal("die_result",currentNumber)

func _on_static_body_3d_input_event(_camera, event, _position, _normal, _shape_idx):
	var mouse_click = event as InputEventMouseButton
	if mouse_click and mouse_click.button_index == 1 and mouse_click.pressed:
		roll()

func new_texture(image):
	var newMaterial = StandardMaterial3D.new()
	newMaterial.albedo_texture = ImageTexture.create_from_image(image)
	$dice/Cube.set_surface_override_material(0,newMaterial)
