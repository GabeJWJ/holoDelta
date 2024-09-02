extends Node3D

signal fuda_clicked
signal mouse_entered
signal mouse_exited

@export var cardList = []
@export var archive := false
@onready var count = $Count
@onready var looking = $Looking
var database

# Called when the node enters the scene tree for the first time.
func _ready():
	count.rotation -= rotation
	looking.rotation -= rotation
	if archive:
		database = SQLite.new()
		database.read_only = true
		if OS.has_feature("editor"):
			database.path = "res://cardData.db"
		else:
			database.path = OS.get_executable_path().get_base_dir() + "/cardData.db"
		database.open_db()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func update_size():
	if cardList.size() == 0:
		visible = false
	else:
		if archive:
			archive_texture_sanity.rpc(cardList[0].cardNumber, cardList[0].artNum)
		visible = true
		scale.y = 0.02 * cardList.size()
		count.text = str(cardList.size())

func shuffle():
	cardList.shuffle()
	var tween = get_tree().create_tween()
	tween.tween_property(self,"scale",scale*0.7,0.2)
	tween.tween_property(self,"scale",scale,0.2)
	update_size()

@rpc("any_peer", "call_local", "reliable")
func archive_texture_sanity(cardNum, artNum):
	var art_data = database.select_rows("cardHasArt","cardID LIKE '" + cardNum + "' AND art_index = " + str(artNum), ["*"])
	var image
	if art_data.is_empty():
		match Settings.settings.Language:
			"English":
				image = Image.load_from_file("res://Sou_Desu_Ne.png")
			"日本語":
				image = Image.load_from_file("res://Sou_Desu_Ne_JP.png")
	elif art_data[0].unrevealed and !Settings.settings.AllowUnrevealed:
		image = Image.load_from_file("res://spoilers.png")
	else:
		image = Image.new()
		image.load_png_from_buffer(art_data[0].art)
	var newMaterial = StandardMaterial3D.new()
	newMaterial.albedo_texture = ImageTexture.create_from_image(image)
	$fuda/Plane.set_surface_override_material(0,newMaterial)


func _on_static_body_3d_input_event(_camera, event, _position, _normal, _shape_idx):
	var mouse_click = event as InputEventMouseButton
	if mouse_click and mouse_click.button_index == 1 and mouse_click.pressed:
		emit_signal("fuda_clicked")
		

func _update_looking(value:bool,look_count=-1):
	looking.visible = value
	if look_count != -1:
		looking.get_node("Label3D").text = str(look_count)
		looking.get_node("Label3D").visible = true
	else:
		looking.get_node("Label3D").visible = false


func _on_static_body_3d_mouse_entered():
	emit_signal("mouse_entered")


func _on_static_body_3d_mouse_exited():
	emit_signal("mouse_exited")
