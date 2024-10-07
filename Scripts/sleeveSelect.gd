extends Node2D

@export var default_sleeve: CompressedTexture2D
var current_sleeve

# Called when the node enters the scene tree for the first time.
func _ready():
	new_sleeve()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_load_sleeve_pressed():
	$LoadSleeve/LoadDialog.visible = true


func _on_default_pressed():
	new_sleeve()


func _on_load_dialog_file_selected(path):
	new_sleeve(Image.load_from_file(path))

func new_sleeve(image=null):
	current_sleeve = image
	if image == null:
		image = default_sleeve.get_image()
		$Default.disabled = true
	else:
		$Default.disabled = false
		image.resize(309,429)
		current_sleeve = image
	$Preview.texture = ImageTexture.create_from_image(image)
