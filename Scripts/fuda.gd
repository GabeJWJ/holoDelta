#A pile of cards. Used for main deck, cheer deck, archive, and holopower

extends Node3D

signal fuda_clicked
signal mouse_entered
signal mouse_exited
signal shuffled

@export var cardList = [] #The ever important ordered list of cards. Contains full cards, front of list is top of fuda
@export var remaining = 0 #How many cards are remaining in fuda - used to get around one visual bug
@export var archive := false
@onready var count = $Count #Label3D showing remaining
@onready var looking = $Looking #That eye graphic that shows up for looking at the top so-and-so cards in deck

func _ready() -> void:
	#Make sure count and looking are aligned properly for holopower
	count.rotation -= rotation
	looking.rotation -= rotation
	
	#There was a bizarre bug where resizing the window in stretch_mode canvas_items
	# would mess with Label3Ds contained within a Subviewport
	#I made a bug report that was marked as fixed, so an engine update may fix without
	#	the need for this
	get_tree().get_root().size_changed.connect(update_text)

func update_size() -> void:
	#Properly sets the size of the fuda to match how many cards are remaining
	#Also makes sure fuda is visible/invisible as needed and calls the function to
	#	make the archive show the top card
	
	if cardList.size() == 0:
		visible = false
	else:
		if archive:
			update_back.rpc(cardList[0].cardFront)
		visible = true
		scale.y = 0.02 * cardList.size()
		remaining = cardList.size()
		update_text()

@rpc("any_peer", "call_local", "reliable")
func update_back(back : Image) -> void:
	#Changes the texture of the fuda. Used for cosmetics and showing the top card of archive
	#back : Image (309x429 with rounded corners) - the texture to set to
	
	var newMaterial = StandardMaterial3D.new()
	newMaterial.albedo_texture = ImageTexture.create_from_image(back)
	$fuda/Plane.set_surface_override_material(0,newMaterial)

func update_text() -> void:
	#Updates the remaining count text
	
	count.text = str(remaining)

func shuffle() -> void:
	#It fucking shuffles. What do you want from me.
	#In addition to that, it plays an animation and emits a signal so that side can play a sound effect
	
	cardList.shuffle()
	var tween = get_tree().create_tween()
	tween.tween_property(self,"scale",scale*0.7,0.2)
	tween.tween_property(self,"scale",scale,0.2)
	update_size()
	emit_signal("shuffled")

@rpc("any_peer", "call_local", "reliable")
func archive_texture_sanity(cardNum : String, artNum : int) -> void:
	#Sets the texture of the archive to match the given card
	#Kind of outdated - will cause some issues with proxies not showing.
	#cardNum : String (card number) - the unique card number of the top card
	#artNum : int - the alt art index (art_index in cardData.db/cardHasArt)
	
	var art_data = Database.db.select_rows("cardHasArt","cardID LIKE '" + cardNum + "' AND art_index = " + str(artNum), ["*"])
	var newMaterial = StandardMaterial3D.new()
	if art_data.is_empty():
		match Settings.settings.Language:
			"ja":
				newMaterial.albedo_texture = load("res://Sou_Desu_Ne_JP.png")
			_:
				newMaterial.albedo_texture = load("res://Sou_Desu_Ne.png")
	elif art_data[0].unrevealed and !Settings.settings.AllowUnrevealed:
		newMaterial.albedo_texture = load("res://spoilers.png")
	else:
		var image = Image.new()
		image.load_png_from_buffer(art_data[0].art)
		newMaterial.albedo_texture = ImageTexture.create_from_image(image)
	
	$fuda/Plane.set_surface_override_material(0,newMaterial)


func _on_static_body_3d_input_event(_camera, event, _position, _normal, _shape_idx) -> void:
	#Fires when the static body 3d (a bounding rectangle for the fuda) is clicked
	#Only worry about event, which gets immediately cast to an InputEventMouseButton
	
	var mouse_click = event as InputEventMouseButton
	if mouse_click and mouse_click.button_index == 1 and mouse_click.is_released():
		emit_signal("fuda_clicked")

func _update_looking(value:bool,look_count=-1) -> void:
	#Shows/hides the little eye graphic for looking at a deck
	#value : bool - should the graphic be shown or hidden
	#look_count : int - the X in "Look at X". If -1, not shown for full-fuda searches
	
	looking.visible = value
	if look_count != -1:
		looking.get_node("Label3D").text = str(look_count)
		looking.get_node("Label3D").visible = true
	else:
		looking.get_node("Label3D").visible = false


func _on_static_body_3d_mouse_entered() -> void:
	emit_signal("mouse_entered")


func _on_static_body_3d_mouse_exited() -> void:
	emit_signal("mouse_exited")
