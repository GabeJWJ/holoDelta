extends Node3D

signal fuda_clicked

var cardList = []
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
		database.path = "res://cardData.db"
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
	var art_data = database.select_rows("cardHasArt","cardID LIKE '" + cardNum + "' AND art_index = " + str(artNum), ["*"])[0]
	var image = Image.new()
	image.load_png_from_buffer(art_data.art)
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
