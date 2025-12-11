#The little widget that selects sleeves in the deck builder menu
#Contains a preview TextureRect of the sleeve, a Load from file button, and a button to reset to default
#Doesn't send up any signal to deck_creation, the script there just reads current_sleeve directly

extends Node2D

@export var default_sleeve: CompressedTexture2D #Set up so you can drag and drop a default from editor
var current_sleeve: Image
var file_access_web : FileAccessWeb
var is_default : bool:
	get:
		return $Default.disabled

signal updated_sleeve(back_to_default: bool)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	new_sleeve(null, false)
	if OS.has_feature("web"):
		file_access_web = FileAccessWeb.new()
		file_access_web.loaded.connect(_on_web_load_dialog_file_selected)


func _on_load_sleeve_pressed() -> void:
	if OS.has_feature("web"):
		file_access_web.open(".png,.webp")
	else:
		$LoadSleeve/LoadDialog.visible = true


func _on_default_pressed() -> void:
	new_sleeve()


func _on_load_dialog_file_selected(path : String) -> void:
	new_sleeve(Image.load_from_file(path))

func _on_web_load_dialog_file_selected(file_name: String, type: String, base64_data: String) -> void:
	var data = Marshalls.base64_to_raw(base64_data)
	var image = Image.new()
	
	match type:
		"image/png":
			image.load_png_from_buffer(data)
			new_sleeve(image)
		"image/webp":
			image.load_webp_from_buffer(data)
			new_sleeve(image)
		_:
			new_sleeve()

func new_sleeve(image=null, emitsignal=true) -> void:
	#Actually sets the sleeve image
	#Passing a null value resets to default
	#image : Image - the new sleeve (or null)
	
	current_sleeve = image
	if image == null:
		image = default_sleeve.get_image()
		$Default.disabled = true
		if emitsignal:
			emit_signal("updated_sleeve", true)
	else:
		$Default.disabled = false
		image.resize(309,429)
		current_sleeve = image
		if emitsignal:
			emit_signal("updated_sleeve", false)
	
	$Preview.texture = ImageTexture.create_from_image(image)
