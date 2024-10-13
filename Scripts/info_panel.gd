extends Node2D

var showing_card_ids = []
var showing_player_id = -1
var showing = []
var showing_grays = []
const gray_text = preload("res://cardover.png")
var current_showing = 0
var cheer_attached = {"White":[],"Green":[],"Red":[],"Blue":[],"Purple":[],"Yellow":[],"Colorless":[]}
@export var allowed_to_scroll = true
var locked = false

var cheer = {"Blue":load("res://CheerIcons/Blue.webp"),"Red":load("res://CheerIcons/Red.webp"),
"Green":load("res://CheerIcons/Green.webp"),"White":load("res://CheerIcons/White.webp"),
"Purple":load("res://CheerIcons/Purple.webp"),"Yellow":load("res://CheerIcons/Yellow.webp"),
"Colorless":load("res://CheerIcons/Colorless.webp")}

# Called when the node enters the scene tree for the first time.
func _ready():
	$LockOff.modulate.a = 0.5
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _new_info(top_card, card_to_show):
	if locked:
		return
	if card_to_show.cardID in showing_card_ids and top_card.get_multiplayer_authority() == showing_player_id:
		_change_show(showing_card_ids.find(card_to_show.cardID) - current_showing)
		return
	
	_clear_showing()
	
	var result = []
	var cheer_result = {"White":[],"Green":[],"Red":[],"Blue":[],"Purple":[],"Yellow":[],"Colorless":[]}
	result.append([top_card.cardFront,top_card.full_desc()])
	showing_card_ids.append(top_card.cardID)
	for stacked_card in top_card.onTopOf:
		showing_card_ids.append(stacked_card.cardID)
		result.append([stacked_card.cardFront,stacked_card.full_desc()])
	for attached_card in top_card.attached:
		if attached_card.cardType == "Cheer":
			var preview = TextureRect.new()
			preview.z_index = 1
			preview.scale = Vector2(0.75,0.75)
			preview.texture = cheer[attached_card.cheer_color]
			cheer_result[attached_card.cheer_color].append(preview)
		else:
			showing_card_ids.append(attached_card.cardID)
			result.append([attached_card.cardFront,attached_card.full_desc()])
	
	_set_showing(result,cheer_result)
	showing_player_id = card_to_show.get_multiplayer_authority()

func _set_showing(to_show,cheer_show):
	cheer_attached = cheer_show
	var max_offset = clamp(100 * (to_show.size() - 1),75,140)
	var each_offset = 75
	if to_show.size() > 1:
		each_offset = clamp((max_offset-10)/(to_show.size()-1),0,75)
		$ScrollIcon.visible = true
	else:
		$ScrollIcon.visible = false
	for i in range(to_show.size()):
		var entry = to_show[-i-1]
		var preview = TextureRect.new()
		$Info.add_child(preview)
		preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		preview.size = Vector2(150,209)
		preview.position = Vector2(max_offset,10) - (i * Vector2(each_offset,0))
		preview.texture = entry[0]
		showing.insert(0,[preview,entry[1]])
		var gray = TextureRect.new()
		$Info.add_child(gray)
		gray.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		gray.size = Vector2(150,209)
		gray.position = Vector2(max_offset,10) - (i * Vector2(each_offset,0))
		gray.texture = gray_text
		showing_grays.insert(0,gray)
	var cheer_i = 0
	var total_cheer = 0
	for cheer_color in cheer_attached:
		total_cheer += cheer_attached[cheer_color].size()
	each_offset = 30
	if total_cheer > 9:
		each_offset = clamp(270/(total_cheer),0,30)
	
	for cheer_color in cheer_attached:
		for icon in cheer_attached[cheer_color]:
			$Info.add_child(icon)
			icon.position = Vector2(15+(each_offset*cheer_i),190)
			cheer_i += 1
	_show_specific(0)

func _show_specific(showing_id):
	$Info/ScrollContainer/CardText.text = showing[showing_id][1]
	showing[showing_id][0].z_index = 1
	showing[showing_id][0].position.y = 3
	showing_grays[showing_id].visible = false
	current_showing = showing_id

func _change_show(change=1):
	showing[current_showing][0].z_index = 0
	showing[current_showing][0].position.y = 10
	showing_grays[current_showing].visible = true
	_show_specific(clamp(current_showing+change,0,showing.size()-1))

func _clear_showing():
	for entry in showing:
		entry[0].queue_free()
	showing.clear()
	for entry in showing_grays:
		entry.queue_free()
	showing_grays.clear()
	for cheer_color in cheer_attached:
		for icon in cheer_attached[cheer_color]:
			icon.queue_free()
		cheer_attached[cheer_color].clear()
	$Info/ScrollContainer/CardText.text = ""
	showing_card_ids = []
	showing_player_id = -1
	$ScrollIcon.visible = false

func update_word_wrap():
	match Settings.settings.Language:
		"English":
			$Info/ScrollContainer/CardText.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		"日本語":
			$Info/ScrollContainer/CardText.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY

func _input(event):
	var mouse_pos = get_viewport().get_mouse_position()
	if allowed_to_scroll and event is InputEventMouseButton and !(mouse_pos.x < 370 and mouse_pos.y > 220) and showing.size() > 1:
		if event.is_pressed():
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				_change_show(-1)
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				_change_show()
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_CTRL:
			locked = !locked
			if locked:
				$LockOff.modulate.a = 1
			else:
				$LockOff.modulate.a = 0.5
