extends Node3D

signal fuda_clicked
signal mouse_entered
signal mouse_exited
signal shuffled

@export var cardList = []
@export var remaining = 0
@export var archive := false
@onready var count = $Count
@onready var looking = $Looking

# Called when the node enters the scene tree for the first time.
func _ready():
	count.rotation -= rotation
	looking.rotation -= rotation
	get_tree().get_root().size_changed.connect(update_text)


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
		remaining = cardList.size()
		update_text()

func update_back(back):
	var newMaterial = StandardMaterial3D.new()
	newMaterial.albedo_texture = ImageTexture.create_from_image(back)
	$fuda/Plane.set_surface_override_material(0,newMaterial)

func update_text():
	count.text = str(remaining)

func shuffle():
	cardList.shuffle()
	var tween = get_tree().create_tween()
	tween.tween_property(self,"scale",scale*0.7,0.2)
	tween.tween_property(self,"scale",scale,0.2)
	update_size()
	emit_signal("shuffled")

@rpc("any_peer", "call_local", "reliable")
func archive_texture_sanity(cardNum, artNum):
	var art_data = Database.db.select_rows("cardHasArt","cardID LIKE '" + cardNum + "' AND art_index = " + str(artNum), ["*"])
	var newMaterial = StandardMaterial3D.new()
	if art_data.is_empty():
		match Settings.settings.Language:
			"English":
				newMaterial.albedo_texture = load("res://Sou_Desu_Ne.png")
			"日本語":
				newMaterial.albedo_texture = load("res://Sou_Desu_Ne_JP.png")
	elif art_data[0].unrevealed and !Settings.settings.AllowUnrevealed:
		newMaterial.albedo_texture = load("res://spoilers.png")
	else:
		var image = Image.new()
		image.load_png_from_buffer(art_data[0].art)
		newMaterial.albedo_texture = ImageTexture.create_from_image(image)
	
	$fuda/Plane.set_surface_override_material(0,newMaterial)


func _on_static_body_3d_input_event(_camera, event, _position, _normal, _shape_idx):
	var mouse_click = event as InputEventMouseButton
	if mouse_click and mouse_click.button_index == 1 and mouse_click.is_released():
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
