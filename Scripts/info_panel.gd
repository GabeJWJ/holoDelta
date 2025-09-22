#The info panel on the left showing information on the card hovered over
#Oof I did this a while ago bear with me
#Basically it contains a list of cards to show keeping track of id, image, and text
#But that's split up into two different lists for some reason

extends Node2D

var showing_card_ids = [] #This is used for one thing - hovering over a card attached to the card you were already looking at
var showing = [] #A list of pairs [card image : TextureRect, card text : String]
var showing_grays = [] #A list of transparent gray TextureRects positioned over the cards to dull not shown cards
const gray_text = preload("res://cardover.png")
var current_showing = 0
var cheer_attached = {"White":[],"Green":[],"Red":[],"Blue":[],"Purple":[],"Yellow":[],"Colorless":[]} #For each color a list of TextureRects containing the cheer icon
@export var allowed_to_scroll = true
var locked = false

var cheer = {"Blue":load("res://CheerIcons/Blue.webp"),"Red":load("res://CheerIcons/Red.webp"),
"Green":load("res://CheerIcons/Green.webp"),"White":load("res://CheerIcons/White.webp"),
"Purple":load("res://CheerIcons/Purple.webp"),"Yellow":load("res://CheerIcons/Yellow.webp"),
"Colorless":load("res://CheerIcons/Colorless.webp")}

func _new_info(top_card, card_to_show) -> void:
	#Reads all of the proper info and passes it along to _set_showing to display
	#top_card : Card - the card on top of the stack that all attached cards are read from
	#card_to_show : Card - the specific card in the stack you want to look at
	
	if locked:
		return
	
	#Reset and set up
	#result will (indirectly) become showing
	#cheer_result will become cheer_attached
	_clear_showing()
	var result = []
	var cheer_result = {"White":[],"Green":[],"Red":[],"Blue":[],"Purple":[],"Yellow":[],"Colorless":[]}
	
	#We add the cards in the order top_card, top_card.onTopOf, top_card.attached (skipping cheers)
	showing_card_ids.append(top_card.cardID)
	result.append([top_card.cardFront,top_card.full_desc()])
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
	
	_set_showing(result, cheer_result, showing_card_ids.find(card_to_show.cardID))

func _set_showing(to_show : Array, cheer_show : Dictionary, start_index : int) -> void:
	#Actually physically sets the display according to passed values
	#to_show : Array of [Image, String] - the cards to show, in order
	#cheer_show : Dictionary of String:(Array of TextureRect) - for each color, a list of cheer icons
	#start_index : int - what index of to_show is already selected
	
	cheer_attached = cheer_show
	
	#The cards should be spaced out nicely, but they need to all fit on the panel
	#This code will dynamically figure out how far apart they should be
	#Also, if there are multiple cards being shown will show Cyber's scroll wheel icon
	var max_offset = clamp(100 * (to_show.size() - 1),75,140)
	var each_offset = 75
	if to_show.size() > 1:
		each_offset = clamp((max_offset-10)/(to_show.size()-1),0,75)
		$ScrollIcon.visible = true
		%ScrollIconTimer.start()
	else:
		$ScrollIcon.visible = false
	
	#Creates showing and showing_grays based on to_show
	#Goes in reverse order so that the cards at the front of the list will naturally be on top
	#Otherwise we'd have to mess with child indices
	for i in range(to_show.size()):
		var entry = to_show[-i-1]
		var preview = TextureRect.new()
		$Info.add_child(preview)
		preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE #Will refuse to shrink without this
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
	
	#Similarly dynamically figured out spacing for the cheer icons
	var cheer_i = 0
	var total_cheer = 0
	for cheer_color in cheer_attached:
		total_cheer += cheer_attached[cheer_color].size()
	each_offset = 30
	if total_cheer > 9:
		each_offset = clamp(270/(total_cheer),0,30)
	
	#We don't bother with reverse order here, though we could
	for cheer_color in cheer_attached:
		for icon in cheer_attached[cheer_color]:
			$Info.add_child(icon)
			icon.position = Vector2(15+(each_offset*cheer_i),190)
			cheer_i += 1
	
	_show_specific(start_index)

func _show_specific(showing_id):
	#Shows a specific card in the stack
	#The gray corresponding is hidden and the preview is moved up a little and placed over the others
	#showing_id : int - the index of showing to show
	
	%CardText.text = showing[showing_id][1]
	showing[showing_id][0].z_index = 1
	showing[showing_id][0].position.y = 3
	showing_grays[showing_id].visible = false
	current_showing = showing_id

func _change_show(change=1) -> void:
	#Cycles the current showed card in the stack
	#change : int - the index delta
	
	showing[current_showing][0].z_index = 0
	showing[current_showing][0].position.y = 10
	showing_grays[current_showing].visible = true
	_show_specific(clamp(current_showing+change,0,showing.size()-1))

func _clear_showing() -> void:
	#Resets the visuals
	
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
	%CardText.text = ""
	showing_card_ids = []
	$ScrollIcon.visible = false

func update_word_wrap() -> void:
	#For some reason, Japanese won't word wrap under word smart mode when exported
	#It works fine in editor, but completely breaks when exported
	#So we switch to arbitrary mode which is ugly but at least you can read it
	
	match Settings.settings.Language:
		"ja":
			%CardText.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
		_:
			%CardText.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func _input(event) -> void:
	#We're looking for scroll wheel movement to cycle through cards in the stack
	#And a LockInfo action (CTRL by default) to lock/unlock the panel
	
	var mouse_pos = get_viewport().get_mouse_position()
	if allowed_to_scroll and event is InputEventMouseButton and !(mouse_pos.x < 370 and mouse_pos.y > 220) and showing.size() > 1:
		if event.is_pressed():
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				_change_show(-1)
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				_change_show()
	if event is InputEventKey and event.pressed:
		if event.is_action_pressed("LockInfo") and (showing.size() != 0 or locked):
			locked = !locked
			if locked:
				$LockOff.modulate.a = 1
			else:
				$LockOff.modulate.a = 0.25

func _on_scroll_icon_timer_timeout() -> void:
	$ScrollIcon.visible = false
