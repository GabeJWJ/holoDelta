#The little widget that selects sleeves in the deck builder menu
#Contains a preview TextureRect of the sleeve, a Load from file button, and a button to reset to default
#Doesn't send up any signal to deck_creation, the script there just reads current_sleeve directly

extends Node2D

@export var default_sleeve: CompressedTexture2D #Set up so you can drag and drop a default from editor
var current_sleeve: Image

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	new_sleeve()


func _on_load_sleeve_pressed() -> void:
	$LoadSleeve/LoadDialog.visible = true


func _on_default_pressed() -> void:
	new_sleeve()


func _on_load_dialog_file_selected(path : String) -> void:
	new_sleeve(Image.load_from_file(path))

func new_sleeve(image=null) -> void:
	#Actually sets the sleeve image
	#Passing a null value resets to default
	#image : Image - the new sleeve (or null)
	
	current_sleeve = image
	if image == null:
		image = default_sleeve.get_image()
		$Default.disabled = true
	else:
		$Default.disabled = false
		image.resize(309,429)
		current_sleeve = image
	$Preview.texture = ImageTexture.create_from_image(image)
