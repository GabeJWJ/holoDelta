extends Node2D

@onready var popup = $PopupMenu
@onready var prompt = $CanvasLayer/Prompt
@onready var lookAt = $CanvasLayer/ScrollContainer
@onready var lookAtList = $CanvasLayer/ScrollContainer/LookAt
@onready var cancel = $CanvasLayer/Cancel

@onready var centerZone = $Zones/Center
@onready var collabZone = $Zones/Collab
@onready var backZone1 = $Zones/Back1
@onready var backZone2 = $Zones/Back2
@onready var backZone3 = $Zones/Back3
@onready var backZone4 = $Zones/Back4
@onready var backZone5 = $Zones/Back5
@onready var backZone6 = $Zones/Back6

@onready var deck = $SubViewportContainer/SubViewport/Node3D/DECK
@onready var cheerDeck = $SubViewportContainer/SubViewport/Node3D/CHEERDECK
@onready var archive = $SubViewportContainer/SubViewport/Node3D/ARCHIVE
@onready var holopower = $SubViewportContainer/SubViewport/Node3D/HOLOPOWER
@onready var die = $SubViewportContainer/SubViewport/Node3D/Die
@onready var spMarker = $SPmarker

var currentCard = -1
var currentFuda = null
var currentAttached = null
var currentPrompt = -1
var currentAttacking = ["", ""]
var playing = null
var revealed = []

@onready var zones = [[centerZone,-1], [collabZone,-1], [backZone1,-1], [backZone2,-1], [backZone3,-1], [backZone4,-1], [backZone5,-1], [backZone6,-1]]
var syncedZones = {}

const card = preload("res://Scenes/card.tscn")
const betterButton = preload("res://Scenes/better_texture_button.tscn")

var all_cards = []
var oshiCard
var hand = []
var life = []

@export var oshi:Array
@export var deckList:Array
@export var cheerDeckList:Array

@export var defaultCheer:CompressedTexture2D = preload("res://cheerBack.png")
@export var defaultMain:CompressedTexture2D = preload("res://holoBack.png")
@export var mainSleeve:PackedByteArray
@export var cheerSleeve:PackedByteArray
@export var oshiSleeve:PackedByteArray
@export var playmatBuffer:PackedByteArray
@export var diceBuffer:PackedByteArray

@export var preliminary_phase = true
var penalty = 0
var preliminary_holomem_in_center = false
@export var can_do_things = false
@export var forced_mulligan_cards = []

@export var is_turn = false
var first_turn = true
var player1 = false
@export var step = 1
var collabed = false
var used_limited = false
var used_baton_pass = false
var used_oshi_skill = false
var used_sp_oshi_skill = false
var can_undo_shuffle_hand = null
signal ended_turn
signal made_turn_choice(choice)
signal rps(choice)
signal mulligan_done
signal ready_decided

signal card_info_set(top_card, card_to_show)
signal card_info_clear

signal entered_list
signal exited_list

signal sent_game_message(message)


func _enter_tree():
	set_multiplayer_authority(name.to_int())

# Called when the node enters the scene tree for the first time.
func _ready():
	tr("DECK")
	tr("CHEERDECK")
	tr("ARCHIVE")
	tr("HOLOPOWER")
	# for POT generation
	
	if name != "1":
		position = Vector2(0,-1044)
		rotation = -3.141
		$SubViewportContainer/SubViewport/Node3D.position += Vector3(1000,0,1000)
	
	$SubViewportContainer.set_multiplayer_authority(name.to_int())
	
	if name.to_int() != 1:
		visible = false
	
	if is_multiplayer_authority():
		holopower.count.position += Vector3(0.3,0,4.6)
		holopower.looking.position += Vector3(3,0,0)
	else:
		deck.count.rotate_y(3.141)
		deck.looking.rotate_y(3.141)
		cheerDeck.count.rotate_y(3.141)
		archive.count.rotate_y(3.141)
		holopower.count.rotate_y(3.141)
		deck.count.position += Vector3(-3,0,4.6)
		cheerDeck.count.position += Vector3(-3,0,4.6)
		archive.count.position += Vector3(-3,0,4.6)
		holopower.count.position += Vector3(-3,0,0)
		holopower.looking.position += Vector3(0,0,4.6)
	
	if is_multiplayer_authority():
		var deckInfo = get_parent().deckInfo
		oshi = deckInfo.oshi
		deckList = deckInfo.deck
		cheerDeckList = deckInfo.cheerDeck
		if deckInfo.has("sleeve"):
			mainSleeve = deckInfo.sleeve
		if deckInfo.has("cheerSleeve"):
			cheerSleeve = deckInfo.cheerSleeve
		if deckInfo.has("oshiSleeve"):
			oshiSleeve = deckInfo.oshiSleeve
		if get_parent().playmat:
			playmatBuffer = get_parent().playmat.save_webp_to_buffer(true)
			$gradient.texture = ImageTexture.create_from_image(get_parent().playmat)
		if get_parent().dice:
			diceBuffer = get_parent().dice.save_webp_to_buffer(true)
			$SubViewportContainer/SubViewport/Node3D/Die.new_texture(get_parent().dice)
	else:
		if playmatBuffer and !playmatBuffer.is_empty():
			var image = Image.new()
			image.load_webp_from_buffer(playmatBuffer)
			$gradient.texture = ImageTexture.create_from_image(image)
		if diceBuffer and !diceBuffer.is_empty():
			var image = Image.new()
			image.load_webp_from_buffer(diceBuffer)
			$SubViewportContainer/SubViewport/Node3D/Die.new_texture(image)
	
	
	
	var oshiBack
	if oshiSleeve.is_empty():
		oshiBack = defaultCheer.get_image()
	else:
		var image = Image.new()
		image.load_webp_from_buffer(oshiSleeve)
		oshiBack = image
	oshiCard = create_card(oshi[0],oshi[1],oshiBack)
	oshiCard.position = Vector2(430,-223)
	oshiCard.visible = false
	oshiCard.z_index = 1
	
	var cheerBack
	if cheerSleeve.is_empty():
		cheerBack = defaultCheer.get_image()
	else:
		var image = Image.new()
		image.load_webp_from_buffer(cheerSleeve)
		cheerBack = image
	for info in cheerDeckList:
		for i in range(info[1]):
			var newCard1 = create_card(info[0],info[2],cheerBack)
			cheerDeck.cardList.append(newCard1)
			newCard1.visible = false
	
	var mainBack
	if mainSleeve.is_empty():
		mainBack = defaultMain.get_image()
	else:
		var image = Image.new()
		image.load_webp_from_buffer(mainSleeve)
		mainBack = image
	for info in deckList:
		for i in range(info[1]):
			var newCard1 = create_card(info[0],info[2],mainBack)
			deck.cardList.append(newCard1)
			newCard1.visible = false
			newCard1.z_index = 1
	
	deck.cardList.shuffle()
	cheerDeck.cardList.shuffle()
	
	deck.update_size()
	deck.update_back(mainBack)
	cheerDeck.update_size()
	cheerDeck.update_back(cheerBack)
	archive.update_size()
	holopower.update_size()
	holopower.update_back(mainBack)
	
	deck.set_multiplayer_authority(name.to_int())
	cheerDeck.set_multiplayer_authority(name.to_int())
	archive.set_multiplayer_authority(name.to_int())
	holopower.set_multiplayer_authority(name.to_int())
	die.set_multiplayer_authority(name.to_int())
	
	move_child($Zones,-1)

func _start():
	specialStart.rpc()

@rpc("any_peer","call_remote","reliable")
func specialStart():
	visible = true
	$CanvasLayer/Question.visible = true

func _rps(choice):
	$CanvasLayer/Question/Label.text = tr("RPS_WAIT")
	$CanvasLayer/Question/Rock.disabled = true
	$CanvasLayer/Question/Paper.disabled = true
	$CanvasLayer/Question/Scissors.disabled = true
	emit_signal("rps",choice)

@rpc("any_peer","call_remote","reliable")
func specialRestart():
	$CanvasLayer/Question/Label.text = tr("RPS_TIED")
	$CanvasLayer/Question/Rock.disabled = false
	$CanvasLayer/Question/Paper.disabled = false
	$CanvasLayer/Question/Scissors.disabled = false

@rpc("any_peer","call_remote","reliable")
func rps_end():
	$CanvasLayer/Question.visible = false
	$CanvasLayer/Question/Rock.visible = false
	$CanvasLayer/Question/Paper.visible = false
	$CanvasLayer/Question/Scissors.visible = false
	oshiCard.flipDown.rpc()
	oshiCard.visible = true

func _made_turn_choice(choice:bool):
	$"CanvasLayer/Go First".visible = false
	$"CanvasLayer/Go Second".visible = false
	emit_signal("made_turn_choice",choice)

@rpc("any_peer","call_remote","reliable")
func _show_turn_choice():
	$"CanvasLayer/Go First".visible = true
	$"CanvasLayer/Go Second".visible = true

@rpc("any_peer","call_remote","reliable")
func specialStart2():
	draw(7)
	
	$CanvasLayer/Question/Label.text = tr("MULLIGAN_QUESTION")
	$CanvasLayer/Question/Yes.visible = true
	$CanvasLayer/Question/No.visible = true
	$CanvasLayer/Question.visible = true
	
	if !hasLegalHand():
		$CanvasLayer/Question/No.disabled = true
	else:
		$CanvasLayer/Question/No.disabled = false

func yes_mulligan():
	emit_signal("sent_game_message",tr("MESSAGE_MULLIGAN"))
	
	var list_of_ids = []
	for hand_card in hand:
		list_of_ids.append(hand_card.cardID)
	for hand_id in list_of_ids:
		add_to_fuda(hand_id,deck)
		remove_from_hand(hand_id)
	deck.cardList.shuffle()
	
	draw(7-penalty)
	
	if hasLegalHand():
		no_mulligan()
	elif penalty == 6:
		$CanvasLayer/Question/Label.text = tr("LOSS")
		$CanvasLayer/Question/OK.visible = false
	else:
		$CanvasLayer/Question/Label.text = tr("MULLIGAN_FORCED")
		$CanvasLayer/Question/Yes.visible = false
		$CanvasLayer/Question/No.visible = false
		$CanvasLayer/Question/OK.visible = true
		penalty += 1
		if penalty > 1:
			forced_mulligan_cards.append(null)
		for hand_card in hand:
			forced_mulligan_cards.append(hand_card.cardID)

func no_mulligan():
	$CanvasLayer/Question/Label.text = tr('MULLIGAN_WAIT')
	$CanvasLayer/Question/Yes.visible = false
	$CanvasLayer/Question/No.visible = false
	$CanvasLayer/Question/OK.visible = false
	emit_signal("mulligan_done")

@rpc("any_peer","call_remote","reliable")
func specialStart3():
	if get_parent().opponentSide.forced_mulligan_cards.size() > 0:
		$CanvasLayer/OpponentLabel/MulliganWarning.visible = true
		var look_at_mulliganed = []
		for card_id in get_parent().opponentSide.forced_mulligan_cards:
			if card_id == null:
				look_at_mulliganed.append(null)
				continue
			look_at_mulliganed.append(get_parent().opponentSide.all_cards[card_id])
		showLookAt(look_at_mulliganed)
	
	$CanvasLayer/Question.visible = false
	$CanvasLayer/Ready.visible = true
	can_do_things = true

func _call_ready():
	emit_signal("ready_decided")
	$CanvasLayer/Ready.disabled = true
	$CanvasLayer/Ready.text = tr("READY_WAIT")

@rpc("any_peer","call_remote","reliable")
func specialStart4():
	oshiCard.flipUp.rpc()
	
	for zoneInfo in zones:
		if zoneInfo[1] != -1:
			all_cards[zoneInfo[1]].flipUp.rpc()
	
	preliminary_phase = false
	$CanvasLayer/Ready.visible = false
	$CanvasLayer/OpponentLabel.visible = false
	
	if is_turn:
		$"CanvasLayer/End Turn".visible = true
	
	for i in range(oshiCard.life):
		var newLife = cheerDeck.cardList.pop_front()
		life.append(newLife)
		if i > 0 and is_multiplayer_authority():
			move_behind.rpc(newLife.cardID,life[i-1].cardID)
		newLife.trulyHide.rpc()
		newLife.position = Vector2(-960,-145-(53*(6-oshiCard.life+i)))
		newLife.rest()
		newLife.visible = true
	
	cheerDeck.update_size()

func hasLegalHand():
	for actualCard in hand:
		if actualCard.cardType == "Holomem" and actualCard.level == 0:
			return true
	return false


func create_card(number,art_code,back):
	var new_id = all_cards.size()
	var newCard = card.instantiate()
	add_child(newCard,true)
	newCard.name = "Card" + str(new_id)
	newCard.setup_info(number,art_code,back)
	newCard.cardID = new_id
	newCard.attachedTo = new_id
	newCard.card_clicked.connect(_on_card_clicked)
	newCard.card_right_clicked.connect(_on_card_right_clicked)
	newCard.card_mouse_over.connect(update_info)
	#newCard.card_mouse_left.connect(clear_info)
	newCard.move_behind_request.connect(_on_move_behind_request)
	all_cards.append(newCard)
	newCard.set_multiplayer_authority(name.to_int())
	newCard.position = Vector2(1000,1000)
	return newCard

func update_hand():
	var max_offset = clamp(125 * (hand.size() - 1),0,1250)
	var each_offset = 250
	if hand.size() > 1:
		each_offset = clamp(2*max_offset/(hand.size()-1),0,250)
	for i in range(hand.size()):
		hand[i].flipDown.rpc()
		hand[i].position = Vector2(-max_offset - 125,750) + (i * Vector2(each_offset,0))
		hand[i].visible = true
		if i > 0:
			move_behind.rpc(hand[-i-1].cardID,hand[-i].cardID)

func draw(x=1):
	for i in range(x):
		add_to_hand(deck.cardList.pop_front().cardID)
	deck.update_size()
	if x == 1:
		emit_signal("sent_game_message",tr("MESSAGE_DRAW"))
	else:
		emit_signal("sent_game_message",tr("MESSAGE_DRAWX").format({amount = x}))

func mill(fromFuda,toFuda,x=1):
	for i in range(x):
		add_to_fuda(fromFuda.cardList.pop_front().cardID,toFuda)
		_move_sfx.rpc()
	fromFuda.update_size()
	if x == 1:
		emit_signal("sent_game_message", tr("MESSAGE_MILL").format({from = tr(fromFuda.name), to = tr(toFuda.name)}))
	else:
		emit_signal("sent_game_message", tr("MESSAGE_MILLX").format({amount = x, from = tr(fromFuda.name), to = tr(toFuda.name)}))

func find_zone_id(zone):
	for index in range(zones.size()):
		if zones[index][0] == zone:
			return index

func find_in_zone(zone):
	for index in range(zones.size()):
		if zones[index][0] == zone:
			return zones[index][1]

func find_what_zone(card_id):
	for index in range(zones.size()):
		if zones[index][1] == card_id:
			return zones[index][0]

func set_zone_card(zone, new_card):
	for index in range(zones.size()):
		if zones[index][0] == zone:
			zones[index][1] = new_card
	please_sync_zones()

func remove_old_card(old_card,leavingField = false):
	if leavingField:
		var actualCard = all_cards[old_card]
		actualCard.unrest()
		actualCard.attached = []
		actualCard.onTopOf = []
	for index in range(zones.size()):
		if zones[index][1] == old_card:
			zones[index][1] = -1
	please_sync_zones()

func remove_from_hand(old_card, hidden=false):
	for index in range(hand.size()):
		if hand[index].cardID == old_card:
			if !hidden:
				hand[index].flipUp.rpc() #hand[index].cardNumber
			hand.remove_at(index)
			break
	update_hand()

func add_to_hand(new_card):
	var cardToGo = all_cards[new_card]
	
	cardToGo.attached.reverse()
	cardToGo.onTopOf.reverse()
	for newCard in cardToGo.attached:
		add_to_hand(newCard.cardID)
	for newCard in cardToGo.onTopOf:
		add_to_hand(newCard.cardID)
	
	hand.append(all_cards[new_card])
	_draw_sfx.rpc()
	update_hand()

func remove_from_card_list(card_id,list_of_cards):
	var cardToGo = all_cards[card_id]
	
	for i in range(list_of_cards.size()):
		if list_of_cards[i].cardID == card_id:
			list_of_cards[i].visible = true
			list_of_cards.remove_at(i)
			break
	
func remove_from_fuda(card_id,fuda):
	remove_from_card_list(card_id,fuda.cardList)
	
	fuda.update_size()

func remove_from_attached(card_id,attached):
	if all_cards[card_id] in attached.attached:
		remove_from_card_list(card_id,attached.attached)
		all_cards[card_id].attachedTo = card_id
		attached.update_attached()
	elif all_cards[card_id] in attached.onTopOf:
		remove_from_card_list(card_id,attached.onTopOf)
	please_sync_attached_stacked(currentAttached)

func add_to_card_list(card_id,list_of_cards,bottom=false):
	var new_position = 0
	if bottom:
		new_position = list_of_cards.size()
	var cardToGo = all_cards[card_id]
	
	cardToGo.attached.reverse()
	cardToGo.onTopOf.reverse()
	for newCard in cardToGo.attached:
		add_to_card_list(newCard.cardID,list_of_cards,bottom)
		newCard.attachedTo = newCard.cardID
	for newCard in cardToGo.onTopOf:
		add_to_card_list(newCard.cardID,list_of_cards,bottom)
	
	list_of_cards.insert(new_position,cardToGo)
	cardToGo.position = Vector2(1000,1000)
	cardToGo.visible = false

func add_to_fuda(card_id,fuda,bottom=false):
	add_to_card_list(card_id,fuda.cardList,bottom)
	
	fuda.update_size()

func first_unoccupied_back_zone(card_id = null):
	var result
	for zone in zones:
		if zone[0] == centerZone or zone[0] == collabZone: #We're looking for back zones
			pass
		elif zone[1] == -1 and !result: #Found an empty zone (and haven't already found one)
			result = zone[0]
		#Defunct but like... what if, ya know?
		elif card_id != null and zone[1] == card_id: #We also check to make sure the specific card isn't on the backrow, to avoid having "move to back" show up on a card already in the back
			return false
	if result:
		return result
	else:
		return false

func all_unoccupied_back_zones():
	var result = []
	for zone in zones:
		if zone[0] == centerZone or zone[0] == collabZone:
			pass
		elif zone[1] == -1:
			result.append(zone[0])
	
	return result

func all_occupied_zones(only_back=false,except_id=null):
	var result = []
	for zone in zones:
		if only_back and (zone[0] == centerZone or zone[0] == collabZone):
			pass
		elif except_id != null and zone[1] == except_id:
			pass
		elif zone[1] != -1:
			result.append(zone[0])
	
	return result

func all_bloomable_zones(card_check):
	var result = {Settings.bloomCode.OK:[],Settings.bloomCode.Instant:[],Settings.bloomCode.Skip:[]}
	for zone in zones:
		if zone[1] != -1:
			var bloom_code = card_check.can_bloom(all_cards[zone[1]])
			if bloom_code != Settings.bloomCode.No:
				result[bloom_code].append(zone[0])
	
	return result

func move_card_to_zone(card_id, zone):
	all_cards[card_id].move_to(zone.position)
	all_cards[card_id].onstage = true
	
	if find_what_zone(card_id):
		remove_old_card(card_id)
		_move_sfx.rpc()
	else:
		_place_sfx.rpc()
	
	set_zone_card(zone,card_id)

func switch_cards_in_zones(zone_1,zone_2):
	var card1 = all_cards[find_in_zone(zone_1)]
	var card2 = all_cards[find_in_zone(zone_2)]
	var pos2 = zone_2.position
	if card2.rested:
		#For some reason, there's a weird offset when switching a center holomem with a rested back holomem - but not the other way around. This gets around it in a hacky way.
		pos2 -= Vector2(50,50)
	card1.move_to(pos2)
	card2.move_to(zone_1.position)
	_move_sfx.rpc()
	_move_sfx.rpc()
	
	set_zone_card(zone_1,card2.cardID)
	set_zone_card(zone_2,card1.cardID)

func bloom_on_zone(card_to_bloom, zone_to_bloom):
	var bloomee = all_cards[find_in_zone(zone_to_bloom)]
	card_to_bloom.bloom(bloomee)
	set_zone_card(zone_to_bloom,card_to_bloom.cardID)
	remove_from_hand(card_to_bloom.cardID)
	_place_sfx.rpc()
	emit_signal("sent_game_message",tr("MESSAGE_BLOOM").format({fromZone = zone_to_bloom.name, fromName = bloomee.get_card_name(), toName = card_to_bloom.get_card_name(), fromLevel = bloomee.level, toLevel = card_to_bloom.level}))


func show_popup():
	if popup.item_count > 0:
		popup.visible = true
		var over_x = max(0,get_viewport().get_mouse_position().x + popup.size.x - 1280)
		var over_y = max(0,get_viewport().get_mouse_position().y + popup.size.y - 720)
		popup.position = get_viewport().get_mouse_position() - Vector2(over_x,over_y)

func reset_popup():
	popup.clear()
	popup.size = Vector2i(40,40)

func set_prompt(promptText,placeholder=7,charLimit=2):
	prompt.get_node("Input").text = promptText
	prompt.get_node("Input/LineEdit").placeholder_text = str(placeholder)
	prompt.get_node("Input/LineEdit").max_length = charLimit
	prompt.visible = true
	prompt.get_node("Input/LineEdit").grab_focus()
	cancel.visible = true

func remove_prompt():
	prompt.visible = false
	prompt.get_node("Input/LineEdit").text = ""
	currentPrompt = -1
	currentAttacking = ["",""]
	cancel.visible = false

func showLookAt(list_of_cards):
	for i in range(list_of_cards.size()):
		var actualCard = list_of_cards[i]
		if actualCard == null:
			continue
		var newButton = betterButton.instantiate()
		newButton.set_texture(actualCard.cardFront)
		newButton.id = actualCard.cardID
		newButton.pressed.connect(_on_list_card_clicked.bind(actualCard.cardID))
		newButton.mouse_entered.connect(update_info.bind(actualCard.cardID))
		#newButton.mouse_exited.connect(clear_info)
		lookAtList.add_child(newButton)
		newButton.scale = Vector2(0.7,0.7)
		newButton.position = Vector2(210*i+5,5)
	
	lookAtList.custom_minimum_size = Vector2(list_of_cards.size()*220 + 10, 0)
	lookAt.get_h_scroll_bar().custom_minimum_size.y = 30
	lookAt.scroll_horizontal = 0
	
	if lookAtList.get_child_count() >0:
		lookAt.visible = true
		cancel.visible = true
		emit_signal("entered_list")
	else:
		hideLookAt()

@rpc("any_peer","call_remote","reliable")
func showLookAtIDS(list_of_ids):
	var json = JSON.new()
	var list_of_cards = []
	json.parse(list_of_ids)
	for id in json.data:
		list_of_cards.append(all_cards[id])
	showLookAt(list_of_cards)

func removeFromLookAt(card_id):
	var remaining = lookAtList.get_children().size() - 1
	var i = 0
	for newButton in lookAtList.get_children():
		if newButton.id == card_id:
			newButton.queue_free()
		else:
			newButton.position = Vector2(210*i+5,5)
			i+=1
	
	lookAtList.custom_minimum_size = Vector2(remaining*280 + 10, 0)
	
	if remaining == 0:
		hideLookAt()

func hideLookAt(endOfAction=true):
	if currentFuda:
		currentFuda._update_looking(false)
		if currentFuda in [deck, cheerDeck] and currentPrompt != 297:
			currentFuda.shuffle()
	elif currentPrompt == 297:
		deck._update_looking(false)
	
	for newButton in lookAtList.get_children():
		newButton.queue_free()
	lookAt.visible = false
	cancel.visible = false
	emit_signal("exited_list")
	if endOfAction:
		currentPrompt = -1
		currentFuda = null
		currentAttached = null

@rpc("any_peer","call_local","reliable")
func flipSPdown():
	spMarker.texture = load("res://SPdown.png")

@rpc("any_peer","call_remote","reliable")
func sync_attached_stacked(top_card_id,list_of_attached_ids,list_of_stacked_ids):
	var top_card = all_cards[top_card_id]
	top_card.attached.clear()
	top_card.onTopOf.clear()
	for attached_id in list_of_attached_ids:
		top_card.attached.append(all_cards[attached_id])
	for stacked_id in list_of_stacked_ids:
		top_card.onTopOf.append(all_cards[stacked_id])

func please_sync_attached_stacked(top_card):
	var list_of_attached_ids = []
	var list_of_stacked_ids = []
	for attached_card in top_card.attached:
		list_of_attached_ids.append(attached_card.cardID)
	for stacked_card in top_card.onTopOf:
		list_of_stacked_ids.append(stacked_card.cardID)
	sync_attached_stacked.rpc(top_card.cardID,list_of_attached_ids,list_of_stacked_ids)

@rpc("any_peer","call_remote","reliable")
func sync_archive(list_of_inside_ids):
	archive.cardList.clear()
	for inside_id in list_of_inside_ids:
		archive.cardList.append(all_cards[inside_id])

func please_sync_archive():
	var list_of_inside_ids = []
	for archive_card in archive.cardList:
		list_of_inside_ids.append(archive_card.cardID)
	sync_archive.rpc(list_of_inside_ids)

@rpc("any_peer","call_remote","reliable")
func sync_zones(list_of_zones):
	syncedZones = list_of_zones
	for zone in zones:
		zone[1] = list_of_zones[zone[0].name][0]

func please_sync_zones():
	var list_of_inside_ids = {}
	for zone in zones:
		list_of_inside_ids[zone[0].name] = [zone[1], all_cards[zone[1]].get_card_name()]
	sync_zones.rpc(list_of_inside_ids)

func showZoneSelection(zones_list,show_cancel=true):
	for zone in zones_list:
		var card_in_zone = all_cards[find_in_zone(zone)]
		if card_in_zone and card_in_zone.rested:
			zone.rest()
		zone.showButton()
	
	if zones_list.size() > 0:
		if show_cancel:
			cancel.visible = true
	else:
		hideZoneSelection()

func hideZoneSelection():
	for zone in zones:
		zone[0].unrest()
		zone[0].hideButton()
	currentPrompt = -1
	currentCard = -1
	cancel.visible = false

func _on_cancel_pressed():
	var yourSide = get_parent().yourSide
	yourSide.hideLookAt()
	yourSide.remove_prompt()
	yourSide.hideZoneSelection()
	hideLookAt()
	remove_prompt()
	hideZoneSelection()

func _hide_cosmetics():
	for cardB in all_cards:
		if cardB.cardType in ["Cheer","Oshi"]:
			cardB.updateBack(defaultCheer)
		else:
			cardB.updateBack(defaultMain)
	deck.update_back(defaultMain.get_image())
	holopower.update_back(defaultMain.get_image())
	cheerDeck.update_back(defaultCheer.get_image())
	
	$gradient.texture = get_parent().default_playmat
	$SubViewportContainer/SubViewport/Node3D/Die.new_texture(get_parent().default_dice)

func _redo_cosmetics():
	var updated_cheer = false
	var updated_main = false
	for cardB in all_cards:
		match cardB.cardType:
			"Oshi":
				if !oshiSleeve.is_empty():
					var image = Image.new()
					image.load_webp_from_buffer(oshiSleeve)
					cardB.updateBack(ImageTexture.create_from_image(image))
			"Cheer":
				if !cheerSleeve.is_empty():
					var image = Image.new()
					image.load_webp_from_buffer(cheerSleeve)
					cardB.updateBack(ImageTexture.create_from_image(image))
					if !updated_cheer:
						cheerDeck.update_back(image)
						updated_cheer = true
			_:
				if !mainSleeve.is_empty():
					var image = Image.new()
					image.load_webp_from_buffer(mainSleeve)
					cardB.updateBack(ImageTexture.create_from_image(image))
					if !updated_main:
						deck.update_back(image)
						holopower.update_back(image)
						updated_main = true
	if !playmatBuffer.is_empty():
		var image = Image.new()
		image.load_webp_from_buffer(playmatBuffer)
		$gradient.texture = ImageTexture.create_from_image(image)
	if !diceBuffer.is_empty():
		var image = Image.new()
		image.load_webp_from_buffer(diceBuffer)
		$SubViewportContainer/SubViewport/Node3D/Die.new_texture(image)


func _on_zone_enter(zone_id):
	var card_id = zones[zone_id][1]
	if card_id != -1:
		update_info(card_id)

func _on_archive_mouse_entered():
	if archive.cardList.size() > 0:
		update_info(archive.cardList[0].cardID)

@rpc("any_peer","call_remote","reliable")
func update_info(card_id):
	var actualCard = all_cards[card_id]
	var topCard = all_cards[actualCard.attachedTo]
	if !actualCard.trulyHidden and (is_multiplayer_authority() or !actualCard.faceDown):
		emit_signal("card_info_set",topCard,actualCard)

func clear_info():
	emit_signal("card_info_clear")

func _on_move_behind_request(card_id1,card_id2):
	move_behind.rpc(card_id1,card_id2)

@rpc("any_peer","call_local","reliable")
func move_behind(card_id1,card_id2):
	var card_1 = all_cards[card_id1]
	var card_2 = all_cards[card_id2]
	move_child(card_1,card_2.get_index()-1)


func _on_card_clicked(card_id):
	if currentPrompt != -1 or !can_do_things:
		return
	
	reset_popup()
	currentCard = card_id
	
	var actualCard = all_cards[currentCard]
	
	if !is_multiplayer_authority():
		if actualCard.attached.size() > 0:
			popup.add_item(tr("CARD_HOLOMEM_LOOK_ATTACHED"),50)
		if actualCard.onTopOf.size() > 0:
			popup.add_item(tr("CARD_HOLOMEM_LOOK_PAST"),52)
		show_popup()
		return
	
	if preliminary_phase:
		if actualCard.cardType == "Holomem" and actualCard in hand and actualCard.level < 1:
			if !preliminary_holomem_in_center and actualCard.level == 0:
				popup.add_item(tr("CARD_HOLOMEM_PLAY_CENTERHIDDEN"), 102)
			if preliminary_holomem_in_center or actualCard.level == -1 and all_occupied_zones().size() < 6:
				popup.add_item(tr("CARD_HOLOMEM_PLAY_BACKHIDDEN"), 103)
	else:
		match actualCard.cardType:
			"Holomem":
				if is_multiplayer_authority():
					var currentZone = find_what_zone(currentCard)
					if actualCard in hand and is_turn:
						if first_unoccupied_back_zone() and actualCard.level < 1 and all_occupied_zones().size() < 6:
							popup.add_item(tr("CARD_HOLOMEM_PLAY"),100)
						if !first_turn:
							var bloomable = all_bloomable_zones(actualCard)
							if bloomable[Settings.bloomCode.OK].size() > 0:
								popup.add_item(tr("CARD_HOLOMEM_BLOOM"),101)
							if bloomable[Settings.bloomCode.Skip].size() > 0:
								popup.add_item(tr("CARD_HOLOMEM_BLOOM_SKIP"),104)
							if bloomable[Settings.bloomCode.Instant].size() > 0:
								popup.add_item(tr("CARD_HOLOMEM_BLOOM_FAST"),105)
					elif currentZone:
						if is_turn:
							if currentZone == centerZone or currentZone == collabZone and !(first_turn and player1):
								for art in actualCard.holomem_arts:
									popup.add_item(Settings.trans("%s_ART_%s_NAME" % [actualCard.cardNumber, art[0]]), 80+art[0])
								popup.add_separator()
							
							if actualCard.rested:
								popup.add_item(tr("CARD_HOLOMEM_UNREST"), 1)
							else:
								popup.add_item(tr("CARD_HOLOMEM_REST"), 0)
							
							if find_in_zone(centerZone) == -1 and currentZone != collabZone:
								popup.add_item(tr("CARD_HOLOMEM_MOVE_CENTER"), 4)
							if currentZone == collabZone and first_unoccupied_back_zone():
								popup.add_item(tr("CARD_HOLOMEM_MOVE_BACK"), 5)
							if find_in_zone(collabZone) == -1 and currentZone != centerZone and !actualCard.rested and deck.cardList.size() > 0 and !collabed:
								popup.add_item(tr("CARD_HOLOMEM_COLLAB"), 6)
							if currentZone == centerZone and all_occupied_zones(true).size() > 0 and !used_baton_pass:
								popup.add_item(tr("CARD_HOLOMEM_BATON"), 7)
							
							popup.add_separator()
						
						popup.add_item(tr("CARD_HOLOMEM_DAMAGE"), 10)
						if actualCard.damage > 0:
							popup.add_item(tr("CARD_HOLOMEM_HEAL"), 11)
						popup.add_item(tr("CARD_HOLOMEM_EXTRAHP"), 12)
						if actualCard.extra_hp > 0:
							popup.add_item(tr("CARD_HOLOMEM_REMOVEEXTRAHP"), 13)
						
						if actualCard.onTopOf.size() > 0:
							popup.add_separator()
							popup.add_item(tr("CARD_HOLOMEM_UNBLOOM"), 15)
			"Support":
				if actualCard in hand:
					if is_turn:
						if actualCard.supportType in ["Tool","Mascot","Fan"]:
							if all_occupied_zones().size() > 0:
								popup.add_item(tr("CARD_SUPPORT_ATTACH"), 121)
						else:
							var cantUseLimited = used_limited or (first_turn and player1)
							if playing == null and !(actualCard.limited and cantUseLimited):
								popup.add_item(tr("CARD_SUPPORT_PLAY"),120)
				elif playing == currentCard:
					popup.add_item(tr("CARD_SUPPORT_ARCHIVE"),20)
			"Oshi":
				for i in range(actualCard.oshi_skills.size()):
					var skill = actualCard.oshi_skills[i]
					var cost_string
					if skill[1] == -1:
						cost_string = "X"
					else:
						cost_string = str(skill[1])
					var sp_string
					if skill[2]:
						sp_string = " SP "
					else:
						sp_string = " "
					var canUseSkill = (skill[2] and !used_sp_oshi_skill) or (!skill[2] and !used_oshi_skill)
					var canPayCost = (skill[1] >= 0 and holopower.cardList.size() >= skill[1]) or (skill[1] == -1 and holopower.cardList.size() > 0)
					#Will cause problems if an oshi has more than 2 skills
					if canUseSkill and canPayCost:
						popup.add_item(Settings.trans(skill[0]) + sp_string + "-" + cost_string,70+i)
					if ((!skill[2] and used_oshi_skill) or (skill[2] and used_sp_oshi_skill)) and canPayCost:
						popup.add_item(Settings.trans(skill[0]) + sp_string + " (again) -" + cost_string,72+i)
		
		if popup.item_count > 0 and actualCard.cardType != "Oshi" and playing != currentCard:
			popup.add_separator()
		
		if life.size() > 0 and actualCard == life[0] and all_occupied_zones().size() > 0:
			popup.add_item(tr("CARD_CHEER_LIFE_REVEAL"), 30)
		
		if find_what_zone(currentCard):
			var serf = false
			if actualCard.attached.size() > 0:
				popup.add_item(tr("CARD_HOLOMEM_LOOK_ATTACHED"),50)
				serf = true
			if actualCard.onTopOf.size() > 0:
				popup.add_item(tr("CARD_HOLOMEM_LOOK_PAST"),52)
				serf = true
			if serf:
				popup.add_separator()
		
		if actualCard.cardType != "Oshi":
			if actualCard in hand:
				popup.add_item(tr("CARD_HAND_TOPDECK"),110)
				popup.add_item(tr("CARD_HAND_BOTTOMDECK"),111)
				popup.add_item(tr("CARD_HAND_ARCHIVE"),112)
				popup.add_item(tr("CARD_HAND_HOLOPOWER"),113)
			elif find_what_zone(currentCard):
				popup.add_item(tr("CARD_STAGE_ARCHIVE"),2)
				if actualCard.attached.size() == 0:
					popup.add_item(tr("CARD_STAGE_HAND"),3)
				if find_in_zone(collabZone) == -1 and find_what_zone(currentCard) != centerZone:
					popup.add_item(tr("CARD_HOLOMEM_MOVE_COLLAB"), 9)
				if find_what_zone(currentCard) == centerZone and all_occupied_zones(true).size() > 0 :
					popup.add_item(tr("CARD_HOLOMEM_SWITCH"), 8)
			elif currentCard in revealed:
				popup.add_item(tr("CARD_REVEALED_HAND"),21)
				if actualCard.cardType == "Support" and actualCard.supportType in ["Tool","Mascot","Fan"] and all_occupied_zones().size() > 0:
					popup.add_item(tr("CARD_REVEALED_ATTACH"),22)
	
	show_popup()

func _on_card_right_clicked(card_id):
	if preliminary_phase or currentPrompt != -1:
		return
	
	if is_multiplayer_authority() and find_what_zone(card_id):
		var actualCard = all_cards[card_id]
		if actualCard.rested:
			actualCard.unrest()
		else:
			actualCard.rest()

func _on_deck_clicked():
	reset_popup()
	
	if preliminary_phase or currentPrompt != -1:
		return
	
	if is_multiplayer_authority():
		
		popup.add_item(tr("DECK_DRAW"),200)
		popup.add_item(tr("DECK_DRAWX"),201)
		popup.add_item(tr("DECK_ARCHIVE"),202)
		popup.add_item(tr("DECK_ARCHIVEX"),203)
		popup.add_item(tr("DECK_HOLOPOWER"),204)
		
		popup.add_separator()
		popup.add_item(tr("DECK_LOOKX"),297)
		popup.add_item(tr("DECK_SEARCH"),298)
		popup.add_item(tr("DECK_SHUFFLE"),299)
		
		if hand.size() > 0:
			popup.add_separator()
			popup.add_item(tr("DECK_MULLIGAN"), 250)
		if can_undo_shuffle_hand != null:
			popup.add_separator()
			popup.add_item(tr("DECK_MULLIGAN_UNDO"), 251)
		
	show_popup()

func _on_cheer_deck_clicked():
	reset_popup()
	
	if preliminary_phase or currentPrompt != -1:
		return
	
	if is_multiplayer_authority():
		if all_occupied_zones().size() > 0:
			popup.add_item(tr("CHEERDECK_REVEAL"),300)
		
		if popup.item_count > 0:
			popup.add_separator()
		
		popup.add_item(tr("CHEERDECK_SEARCH"),398)
		popup.add_item(tr("CHEERDECK_SHUFFLE"),399)
		
	show_popup()

func _on_archive_clicked():
	if preliminary_phase or currentPrompt != -1:
		return
	
	reset_popup()
	
	popup.add_item(tr("ARCHIVE_SEARCH"),498)
		
	show_popup()

func _on_holopower_clicked():
	reset_popup()
	
	if preliminary_phase or currentPrompt != -1:
		return
	
	if is_multiplayer_authority():
		popup.add_item(tr("HOLOPOWER_ARCHIVE"),500)
		popup.add_item(tr("HOLOPOWER_ARCHIVEX"),501)
		
		popup.add_separator()
		
		popup.add_item(tr("HOLOPOWER_DECK"), 510)
		
		popup.add_separator()
		
		popup.add_item(tr("HOLOPOWER_SEARCH"),598)
		popup.add_item(tr("HOLOPOWER_SHUFFLE"),599)
		
	show_popup()

func _on_list_card_clicked(card_id):
	if preliminary_phase or currentPrompt == -1 or !is_multiplayer_authority():
		return
	
	reset_popup()
	currentCard = card_id
	
	var actualCard = all_cards[currentCard]
	var fullFuda = true
	if currentPrompt in [297]:
		fullFuda = false
	
	#Requires zone target and thus must be broken up by fuda
	match actualCard.cardType:
		"Holomem":
			if first_unoccupied_back_zone() and actualCard.level < 1 and is_turn and all_occupied_zones().size() < 6:
				if currentFuda == deck:
					popup.add_item(tr("LIST_DECK_HOLOMEM_PLAY"),600)
				elif currentFuda == archive:
					popup.add_item(tr("LIST_ARCHIVE_HOLOMEM_PLAY"),610)
			if all_bloomable_zones(actualCard)[Settings.bloomCode.OK].size() > 0 and is_turn and !first_turn:
				if currentFuda == deck:
					popup.add_item(tr("LIST_DECK_HOLOMEM_BLOOM"),601)
				elif currentFuda == archive:
					popup.add_item(tr("LIST_ARCHIVE_HOLOMEM_BLOOM"),611)
		"Cheer":
			if all_occupied_zones().size() > 0:
				if currentFuda == cheerDeck:
					popup.add_item(tr("LIST_CHEERDECK_CHEER_ATTACH"),602)
				elif currentFuda == archive:
					popup.add_item(tr("LIST_ARCHIVE_CHEER_ATTACH"),612)
				elif currentAttached != null and all_occupied_zones().size() > 1:
					popup.add_item(tr("LIST_ATTACHED_CHEER_ATTACH"),622)
			
			if life.size() < 6:
				popup.add_item(tr("LIST_CHEER_LIFE"),603)
	
	if currentFuda in [deck,archive,holopower] and actualCard.cardType != "Cheer" and revealed.size() < 10:
		popup.add_item(tr("LIST_CARD_REVEAL"), 630)
	
	if popup.item_count > 0:
		popup.add_separator()
	
	#Done automatically and thus does not need to be broken up by fuda.
	if actualCard.cardType != "Cheer":
		popup.add_item(tr("LIST_CARD_HAND"), 650)
	
	if (!fullFuda or currentFuda != deck) and actualCard.cardType != "Cheer":
		popup.add_item(tr("LIST_CARD_TOPDECK"),651)
		popup.add_item(tr("LIST_CARD_BOTTOMDECK"),652)
	if (!fullFuda or currentFuda != cheerDeck) and actualCard.cardType == "Cheer":
		popup.add_item(tr("LIST_CARD_TOPCHEERDECK"),653)
		popup.add_item(tr("LIST_CARD_BOTTOMCHEERDECK"),654)
	if currentFuda != archive:
		popup.add_item(tr("LIST_CARD_ARCHIVE"),655)
	if currentFuda != holopower and actualCard.cardType != "Cheer":
		popup.add_item(tr("LIST_CARD_HOLOPOWER"),656)
	
	show_popup()


func _on_popup_menu_id_pressed(id):
	match id:
		0: #Rest
			all_cards[currentCard].rest()
			currentCard = -1
		1: #Unrest
			all_cards[currentCard].unrest()
			currentCard = -1
		2: #Archive
			var actualCard = all_cards[currentCard]
			emit_signal("sent_game_message",tr("MESSAGE_STAGE_ARCHIVE").format({fromZone = find_what_zone(currentCard).name, fromName = actualCard.get_card_name()}))
			actualCard.clear_damage()
			actualCard.clear_extra_hp()
			actualCard.unrest()
			add_to_fuda(currentCard,archive)
			remove_old_card(currentCard,true)
			if playing == currentCard:
				playing = null
			please_sync_attached_stacked(actualCard)
			please_sync_archive()
			currentCard = -1
			_move_sfx.rpc()
		3: #Return to Hand
			var actualCard = all_cards[currentCard]
			emit_signal("sent_game_message",tr("MESSAGE_STAGE_HAND").format({fromZone = find_what_zone(currentCard).name, fromName = actualCard.get_card_name()}))
			actualCard.clear_damage()
			actualCard.clear_extra_hp()
			actualCard.unrest()
			add_to_hand(currentCard)
			remove_old_card(currentCard,true)
			please_sync_attached_stacked(actualCard)
			currentCard = -1
		4: #Move to Center
			emit_signal("sent_game_message",tr("MESSAGE_STAGE_CENTER").format({fromZone = find_what_zone(currentCard).name, fromName = all_cards[currentCard].get_card_name()}))
			move_card_to_zone(currentCard,centerZone)
			currentCard = -1
			_move_sfx.rpc()
		5: #Move to Back
			showZoneSelection(all_unoccupied_back_zones())
			currentPrompt = 5
		6: #Collab
			emit_signal("sent_game_message",tr("MESSAGE_STAGE_COLLAB").format({fromZone = find_what_zone(currentCard).name, fromName = all_cards[currentCard].get_card_name()}))
			move_card_to_zone(currentCard,collabZone)
			if deck.cardList.size() > 0:
				mill(deck,holopower)
			currentCard = -1
			collabed = true
			_move_sfx.rpc()
		7: #Baton Pass
			showZoneSelection(all_occupied_zones(true))
			currentPrompt = 7
		8: #Switch to Back
			showZoneSelection(all_occupied_zones(true))
			currentPrompt = 8
		9:
			emit_signal("sent_game_message",tr("MESSAGE_STAGE_MOVECOLLAB").format({fromZone = find_what_zone(currentCard).name, fromName = all_cards[currentCard].get_card_name()}))
			move_card_to_zone(currentCard,collabZone)
			currentCard = -1
			_move_sfx.rpc()
		10: #Add Damage
			set_prompt(tr("PROMPT_DAMAGE") + "\nX=",20,3)
			currentPrompt = 10
		11: #Remove Damage
			set_prompt(tr("PROMPT_HEAL") + "\nX=",20,3)
			currentPrompt = 11
		12: #Add Extra HP
			set_prompt(tr("PROMPT_EXTRAHP") + "\nX=",10,2)
			currentPrompt = 12
		13: #Remove Extra HP
			set_prompt(tr("PROMPT_REMOVEEXTRAHP") + "\nX=",10,2)
			currentPrompt = 13
		15: #Unbloom
			var actualCard = all_cards[currentCard]
			var newCard = actualCard.onTopOf[0].cardID
			emit_signal("sent_game_message",tr("MESSAGE_STAGE_UNBLOOM").format({fromZone = find_what_zone(currentCard).name, fromName = actualCard.get_card_name(), toName = all_cards[newCard].get_card_name()}))
			actualCard.unbloom()
			for index in range(zones.size()):
				if zones[index][1] == currentCard:
					zones[index][1] = newCard
			add_to_hand(currentCard)
			please_sync_attached_stacked(actualCard)
			please_sync_attached_stacked(all_cards[newCard])
			currentCard = -1
		20: #Archive Support in Play
			add_to_fuda(currentCard,archive)
			if playing == currentCard:
				all_cards[currentCard].z_index = 1
			playing = null
			please_sync_archive()
			currentCard = -1
			_move_sfx.rpc()
		21: #Add Revealed Card to Hand
			add_to_hand(currentCard)
			all_cards[currentCard].z_index = 1
			revealed.erase(currentCard)
			currentCard = -1
		22: #Attach Revealed Support
			var possibleZones = all_occupied_zones()
			showZoneSelection(possibleZones)
			currentPrompt = 22
		30: #Reveal and Attach Life
			var possibleZones = all_occupied_zones()
			var cheerCard = all_cards[currentCard]
			remove_from_card_list(currentCard,life)
			cheerCard.flipUp.rpc() #cheerCard.cardNumber
			showZoneSelection(possibleZones,false)
			currentPrompt = 30
		50: #Look At Attached
			currentAttached = all_cards[currentCard]
			showLookAt(currentAttached.attached)
			currentPrompt = 50
		52: #Look At Past Blooms
			currentAttached = all_cards[currentCard]
			showLookAt(currentAttached.onTopOf)
			currentPrompt = 52
		70,71: #Oshi Skill
			var skill = all_cards[currentCard].oshi_skills[id - 70]
			if skill[1] >= 0:
				if skill[2]:
					used_sp_oshi_skill = true
					flipSPdown.rpc()
					emit_signal("sent_game_message", tr("MESSAGE_OSHISKILL_SP").format({skillName = Settings.trans(skill[0])}))
				else:
					used_oshi_skill = true
					emit_signal("sent_game_message", tr("MESSAGE_OSHISKILL").format({skillName = Settings.trans(skill[0])}))
				mill(holopower,archive,skill[1])
				currentCard = -1
				please_sync_archive()
			else:
				set_prompt(tr("PROMPT_OSHICOST") + "\nX=",3)
				currentPrompt = id
		72,73: #Oshi Skill but again
			var skill = all_cards[currentCard].oshi_skills[id - 72]
			if skill[1] >= 0:
				if skill[2]:
					flipSPdown.rpc()
					emit_signal("sent_game_message", tr("MESSAGE_OSHISKILL_SP").format({skillName = Settings.trans(skill[0])}))
				else:
					emit_signal("sent_game_message", tr("MESSAGE_OSHISKILL").format({skillName = Settings.trans(skill[0])}))
				mill(holopower,archive,skill[1])
				currentCard = -1
				please_sync_archive()
			else:
				set_prompt(tr("PROMPT_OSHICOST") + "\nX=",3)
				currentPrompt = id
		80,81: #Holomem Art
			var oppSide = get_parent().opponentSide
			oppSide.showZoneSelection(oppSide.all_occupied_zones())
			oppSide.currentPrompt = id
			currentPrompt = id
		
		100: #Play to Back
			var possibleZones = all_unoccupied_back_zones()
			if zones[0][1] == -1:
				possibleZones.append(centerZone)
			showZoneSelection(possibleZones)
			currentPrompt = 100
		101: #Bloom
			var possibleZones = all_bloomable_zones(all_cards[currentCard])[Settings.bloomCode.OK]
			showZoneSelection(possibleZones)
			currentPrompt = 101
		104: #Skip Bloom
			var possibleZones = all_bloomable_zones(all_cards[currentCard])[Settings.bloomCode.Skip]
			showZoneSelection(possibleZones)
			currentPrompt = 101
		105: #Instant Bloom
			var possibleZones = all_bloomable_zones(all_cards[currentCard])[Settings.bloomCode.Instant]
			showZoneSelection(possibleZones)
			currentPrompt = 101
		102: #Play Hidden to Center
			move_card_to_zone(currentCard,centerZone)
			remove_from_hand(currentCard,true)
			#hideZoneSelection()
			preliminary_holomem_in_center = true
			$CanvasLayer/Ready.disabled = false
			_place_sfx.rpc()
		103: #Play Hidden to Back
			var possibleZones = all_unoccupied_back_zones()
			showZoneSelection(possibleZones)
			currentPrompt = 103
		110: #Return to top of deck
			emit_signal("sent_game_message", tr("MESSAGE_HAND_TOPDECK"))
			add_to_fuda(currentCard,deck)
			remove_from_hand(currentCard)
			currentCard = -1
			can_undo_shuffle_hand = null
			_place_sfx.rpc()
		111: #Return to bottom of deck
			emit_signal("sent_game_message", tr("MESSAGE_HAND_BOTTOMDECK"))
			add_to_fuda(currentCard,deck,-1)
			remove_from_hand(currentCard)
			currentCard = -1
			can_undo_shuffle_hand = null
			_place_sfx.rpc()
		112: #Archive
			emit_signal("sent_game_message", tr("MESSAGE_HAND_ARCHIVE").format({cardName = all_cards[currentCard].get_card_name()}))
			add_to_fuda(currentCard,archive)
			remove_from_hand(currentCard)
			please_sync_archive()
			currentCard = -1
			_place_sfx.rpc()
		113: #Holopower
			emit_signal("sent_game_message", tr("MESSAGE_HAND_HOLOPOWER"))
			add_to_fuda(currentCard,holopower)
			remove_from_hand(currentCard)
			currentCard = -1
			_place_sfx.rpc()
		120: #Play Support
			var actualCard = all_cards[currentCard]
			emit_signal("sent_game_message", tr("MESSAGE_HAND_SUPPORT_PLAY").format({cardName = all_cards[currentCard].get_card_name()}))
			if actualCard.limited:
				used_limited = true
			actualCard.z_index = 2
			remove_from_hand(currentCard)
			actualCard.position = Vector2(0,0)
			playing = currentCard
			currentCard = -1
			_place_sfx.rpc()
			
		121: #Attach Support
			var possibleZones = all_occupied_zones()
			showZoneSelection(possibleZones)
			currentPrompt = 121
		
		200: #Draw
			draw()
			can_undo_shuffle_hand = null
		201: #Draw X
			set_prompt(tr("PROMPT_DRAW") + "\nX=")
			currentPrompt = 201
		202: #Mill
			mill(deck,archive)
			please_sync_archive()
			can_undo_shuffle_hand = null
		203: #Mill X
			set_prompt(tr("PROMPT_DECK_ARCHIVE") + "\nX=",3)
			currentPrompt = 203
		204: #Holopower
			mill(deck,holopower)
			can_undo_shuffle_hand = null
		250: #Shuffle Hand Into Deck
			emit_signal("sent_game_message", tr("MESSAGE_DECK_MULLIGAN"))
			var list_of_ids = []
			for hand_card in hand:
				list_of_ids.append(hand_card.cardID)
			can_undo_shuffle_hand = list_of_ids
			for hand_id in list_of_ids:
				add_to_fuda(hand_id,deck)
				remove_from_hand(hand_id)
			deck.shuffle()
		251: #Unshuffle Hand Into Deck
			emit_signal("sent_game_message", tr("MESSAGE_DECK_UNDOMULLIGAN"))
			for hand_id in can_undo_shuffle_hand:
				add_to_hand(hand_id)
				remove_from_fuda(hand_id,deck)
		297: #Look at X
			set_prompt(tr("PROMPT_LOOKATX"),5)
			currentPrompt = 297
		298: #Search Deck
			emit_signal("sent_game_message", tr("MESSAGE_DECK_SEARCH"))
			showLookAt(deck.cardList)
			deck._update_looking(true)
			currentPrompt = 298
			currentFuda = deck
		299: #Shuffle
			emit_signal("sent_game_message", tr("MESSAGE_DECK_SHUFFLE"))
			deck.shuffle()
		
		300: #Reveal and Attach Cheer
			var possibleZones = all_occupied_zones()
			var cheerCard = cheerDeck.cardList.pop_front()
			cheerCard.visible = true
			cheerCard.z_index = 2
			cheerCard.position = Vector2(-1250,-300)
			currentCard = cheerCard.cardID
			cheerDeck.update_size()
			showZoneSelection(possibleZones,false)
			currentPrompt = 300
		398: #Search Cheer Deck
			emit_signal("sent_game_message", tr("MESSAGE_CHEERDECK_SEARCH"))
			showLookAt(cheerDeck.cardList)
			cheerDeck._update_looking(true)
			currentPrompt = 398
			currentFuda = cheerDeck
		399: #Shuffle
			emit_signal("sent_game_message", tr("MESSAGE_CHEERDECK_SHUFFLE"))
			cheerDeck.shuffle()
		
		498: #Search Archive
			showLookAt(archive.cardList)
			currentPrompt = 498
			currentFuda = archive
		
		500: #Holopower to Archive
			mill(holopower,archive)
			please_sync_archive()
		501: #Holopower X to Archive
			set_prompt(tr("PROMPT_HOLOPOWER_ARCHIVE") + "\nX=",3)
			currentPrompt = 501
		510: #Holopower to top of deck
			mill(holopower,deck)
		598: #Search Holopower
			emit_signal("sent_game_message", tr("MESSAGE_HOLOPOWER_SEARCH"))
			showLookAt(holopower.cardList)
			holopower._update_looking(true)
			currentPrompt = 598
			currentFuda = holopower
		599: #Shuffle
			emit_signal("sent_game_message", tr("MESSAGE_HOLOPOWER_SHUFFLE"))
			holopower.shuffle()
		
		600: #Play From Deck
			hideLookAt()
			var possibleZones = all_unoccupied_back_zones()
			if zones[0][1] == -1:
				possibleZones.append(centerZone)
			showZoneSelection(possibleZones)
			currentPrompt = 600
		601: #Bloom From Deck
			hideLookAt()
			var possibleZones = all_bloomable_zones(all_cards[currentCard])[Settings.bloomCode.OK]
			showZoneSelection(possibleZones)
			currentPrompt = 601
		602: #Attach Cheer From Deck
			hideLookAt()
			var possibleZones = all_occupied_zones()
			showZoneSelection(possibleZones)
			currentPrompt = 602
		603: #To Life
			var actualCard = all_cards[currentCard]
			if currentFuda:
				emit_signal("sent_game_message",tr("MESSAGE_FUDA_LIFE").format({fromFuda = tr(currentFuda.name)}))
				remove_from_fuda(currentCard,currentFuda)
				please_sync_archive()
			elif currentAttached:
				emit_signal("sent_game_message",tr("MESSAGE_ATTACHED_LIFE").format({cardName = actualCard.get_card_name(), fromZone = find_what_zone(currentAttached.cardID), fromName = currentAttached.get_card_name()}))
				remove_from_attached(currentCard,currentAttached)
			
			life.insert(0, actualCard)
			actualCard.trulyHide.rpc()
			actualCard.position = Vector2(-960,-145-(53*(6-life.size())))
			actualCard.rest()
			actualCard.visible = true
			for i in range(life.size()):
				if i > 0 and is_multiplayer_authority():
					move_behind.rpc(life[i].cardID,life[i-1].cardID)
			removeFromLookAt(currentCard)
			currentCard = -1
			_move_sfx.rpc()
		610: #Play From Archive
			hideLookAt()
			var possibleZones = all_unoccupied_back_zones()
			if zones[0][1] == -1:
				possibleZones.append(centerZone)
			showZoneSelection(possibleZones)
			currentPrompt = 610
		611: #Bloom From Archive
			hideLookAt()
			var possibleZones = all_bloomable_zones(all_cards[currentCard])[Settings.bloomCode.OK]
			showZoneSelection(possibleZones)
			currentPrompt = 611
		612: #Attach Cheer From Archive
			hideLookAt()
			var possibleZones = all_occupied_zones()
			showZoneSelection(possibleZones)
			currentPrompt = 612
		622: #Attach Cheer From Attach
			var possibleZones = all_occupied_zones(false,currentAttached.cardID)
			hideLookAt(false)
			showZoneSelection(possibleZones)
			currentPrompt = 622
		630: #Reveal Card From Deck
			var actualCard = all_cards[currentCard]
			emit_signal("sent_game_message",tr("MESSAGE_FUDA_REVEAL").format({fromFuda = tr(currentFuda.name), cardName = actualCard.get_card_name()}))
			actualCard.z_index = 2
			remove_from_fuda(currentCard,currentFuda)
			removeFromLookAt(currentCard)
			actualCard.position = Vector2(300,100*revealed.size() - 400)
			revealed.append(currentCard)
			for i in range(revealed.size()):
				if i > 0:
					move_behind.rpc(revealed[-i-1],revealed[-i])
			please_sync_archive()
			currentCard = -1
			can_undo_shuffle_hand = null
			_move_sfx.rpc()
		650: #Add to Hand
			if currentFuda:
				if currentFuda == archive:
					emit_signal("sent_game_message",tr("MESSAGE_ARCHIVE_HAND").format({cardName = all_cards[currentCard].get_card_name()}))
				else:
					emit_signal("sent_game_message",tr("MESSAGE_FUDA_HAND").format({fromFuda = tr(currentFuda.name)}))
				remove_from_fuda(currentCard,currentFuda)
				please_sync_archive()
			elif currentAttached:
				emit_signal("sent_game_message",tr("MESSAGE_ATTACHED_HAND").format(
					{fromZone = find_what_zone(currentAttached.cardID).name, fromName = currentAttached.get_card_name(), cardName = all_cards[currentCard].get_card_name()}))
				remove_from_attached(currentCard,currentAttached)
			all_cards[currentCard].unrest()
			add_to_hand(currentCard)
			removeFromLookAt(currentCard)
			currentCard = -1
			can_undo_shuffle_hand = null
			
		651: #Return to top of deck
			if currentFuda:
				match currentFuda:
					archive:
						emit_signal("sent_game_message",tr("MESSAGE_ARCHIVE_TOPDECK").format({cardName = all_cards[currentCard].get_card_name()}))
					deck:
						emit_signal("sent_game_message",tr("MESSAGE_DECK_TOPDECK"))
					_:
						emit_signal("sent_game_message",tr("MESSAGE_FUDA_TOPDECK").format({fromFuda = tr(currentFuda.name)}))
				remove_from_fuda(currentCard,currentFuda)
				please_sync_archive()
			elif currentAttached:
				emit_signal("sent_game_message",tr("MESSAGE_ATTACHED_TOPDECK").format(
					{fromZone = find_what_zone(currentAttached.cardID).name, fromName = currentAttached.get_card_name(), cardName = all_cards[currentCard].get_card_name()}))
				remove_from_attached(currentCard,currentAttached)
			all_cards[currentCard].unrest()
			add_to_fuda(currentCard,deck)
			removeFromLookAt(currentCard)
			currentCard = -1
			can_undo_shuffle_hand = null
			_move_sfx.rpc()
		652: #Return to bottom of deck
			if currentFuda:
				match currentFuda:
					archive:
						emit_signal("sent_game_message",tr("MESSAGE_ARCHIVE_BOTTOMDECK").format({cardName = all_cards[currentCard].get_card_name()}))
					deck:
						emit_signal("sent_game_message",tr("MESSAGE_DECK_BOTTOMDECK"))
					_:
						emit_signal("sent_game_message",tr("MESSAGE_FUDA_BOTTOMDECK").format({fromFuda = tr(currentFuda.name)}))
				remove_from_fuda(currentCard,currentFuda)
				please_sync_archive()
			elif currentAttached:
				emit_signal("sent_game_message",tr("MESSAGE_ATTACHED_BOTTOMDECK").format(
					{fromZone = find_what_zone(currentAttached.cardID).name, fromName = currentAttached.get_card_name(), cardName = all_cards[currentCard].get_card_name()}))
				remove_from_attached(currentCard,currentAttached)
			all_cards[currentCard].unrest()
			add_to_fuda(currentCard,deck,-1)
			removeFromLookAt(currentCard)
			currentCard = -1
			can_undo_shuffle_hand = null
			_move_sfx.rpc()
		653: #Return to top of cheer deck
			if currentFuda:
				match currentFuda:
					archive:
						emit_signal("sent_game_message",tr("MESSAGE_ARCHIVE_TOPCHEERDECK").format({cardName = all_cards[currentCard].get_card_name()}))
					cheerDeck:
						emit_signal("sent_game_message",tr("MESSAGE_CHEERDECK_TOPCHEERDECK"))
					_:
						emit_signal("sent_game_message",tr("MESSAGE_FUDA_TOPCHEERDECK").format({fromFuda = tr(currentFuda.name)}))
				remove_from_fuda(currentCard,currentFuda)
				please_sync_archive()
			elif currentAttached:
				emit_signal("sent_game_message",tr("MESSAGE_ATTACHED_TOPCHEERDECK").format(
					{fromZone = find_what_zone(currentAttached.cardID).name, fromName = currentAttached.get_card_name(), cardName = all_cards[currentCard].get_card_name()}))
				remove_from_attached(currentCard,currentAttached)
			all_cards[currentCard].unrest()
			add_to_fuda(currentCard,cheerDeck)
			removeFromLookAt(currentCard)
			currentCard = -1
			_move_sfx.rpc()
		654: #Return to bottom of cheer deck
			if currentFuda:
				match currentFuda:
					archive:
						emit_signal("sent_game_message",tr("MESSAGE_ARCHIVE_BOTTOMCHEERDECK").format({cardName = all_cards[currentCard].get_card_name()}))
					cheerDeck:
						emit_signal("sent_game_message",tr("MESSAGE_CHEERDECK_BOTTOMCHEERDECK"))
					_:
						emit_signal("sent_game_message",tr("MESSAGE_FUDA_BOTTOMCHEERDECK").format({fromFuda = tr(currentFuda.name)}))
				remove_from_fuda(currentCard,currentFuda)
				please_sync_archive()
			elif currentAttached:
				emit_signal("sent_game_message",tr("MESSAGE_ATTACHED_BOTTOMCHEERDECK").format(
					{fromZone = find_what_zone(currentAttached.cardID).name, fromName = currentAttached.get_card_name(), cardName = all_cards[currentCard].get_card_name()}))
				remove_from_attached(currentCard,currentAttached)
			all_cards[currentCard].unrest()
			add_to_fuda(currentCard,cheerDeck,-1)
			removeFromLookAt(currentCard)
			currentCard = -1
			_move_sfx.rpc()
		655: #Archive
			if currentFuda:
				emit_signal("sent_game_message",tr("MESSAGE_FUDA_ARCHIVE").format({fromFuda = tr(currentFuda.name), cardName = all_cards[currentCard].get_card_name()}))
				remove_from_fuda(currentCard,currentFuda)
			elif currentAttached:
				emit_signal("sent_game_message",tr("MESSAGE_ATTACHED_ARCHIVE").format(
					{fromZone = find_what_zone(currentAttached.cardID).name, fromName = currentAttached.get_card_name(), cardName = all_cards[currentCard].get_card_name()}))
				remove_from_attached(currentCard,currentAttached)
			all_cards[currentCard].unrest()
			add_to_fuda(currentCard,archive)
			removeFromLookAt(currentCard)
			please_sync_archive()
			currentCard = -1
			_move_sfx.rpc()
		656: #Holopower
			if currentFuda:
				if currentFuda == archive:
					emit_signal("sent_game_message",tr("MESSAGE_ARCHIVE_HOLOPOWER").format({cardName = all_cards[currentCard].get_card_name()}))
				else:
					emit_signal("sent_game_message",tr("MESSAGE_FUDA_HOLOPOWER").format({fromFuda = tr(currentFuda.name)}))
				remove_from_fuda(currentCard,currentFuda)
				please_sync_archive()
			elif currentAttached:
				emit_signal("sent_game_message",tr("MESSAGE_ATTACHED_HOLOPOWER").format(
					{fromZone = find_what_zone(currentAttached.cardID).name, fromName = currentAttached.get_card_name(), cardName = all_cards[currentCard].get_card_name()}))
				remove_from_attached(currentCard,currentAttached)
			all_cards[currentCard].unrest()
			add_to_fuda(currentCard,holopower)
			removeFromLookAt(currentCard)
			currentCard = -1
			_move_sfx.rpc()
			
	reset_popup()
	

func _on_line_edit_text_submitted(new_text):
	if new_text == "":
		new_text = prompt.get_node("Input/LineEdit").placeholder_text
	
	match currentPrompt:
		10: #Add Damage
			var input = new_text.to_int()
			if new_text.is_valid_int() and input > 0:
				var actualCard = all_cards[currentCard]
				actualCard.add_damage(input)
				currentCard = -1
				remove_prompt()
		11: #Remove Damage
			var input = new_text.to_int()
			if new_text.is_valid_int() and input > 0:
				var actualCard = all_cards[currentCard]
				actualCard.add_damage(-1 * input)
				currentCard = -1
				remove_prompt()
		12: #Add Extra HP
			var input = new_text.to_int()
			if new_text.is_valid_int() and input > 0:
				var actualCard = all_cards[currentCard]
				actualCard.add_extra_hp(input)
				currentCard = -1
				remove_prompt()
		13: #Remove Extra HP
			var input = new_text.to_int()
			if new_text.is_valid_int() and input > 0:
				var actualCard = all_cards[currentCard]
				actualCard.add_extra_hp(-1 * input)
				currentCard = -1
				remove_prompt()
		70, 71: #Oshi Skill X Cost
			var input = new_text.to_int()
			if new_text.is_valid_int() and input > 0 and input <= holopower.cardList.size():
				var skill = all_cards[currentCard].oshi_skills[70 - currentPrompt]
				if skill[2]:
					used_sp_oshi_skill = true
					flipSPdown.rpc()
					emit_signal("sent_game_message", tr("MESSAGE_OSHISKILL_SP").format({skillName = Settings.trans(skill[0])}))
				else:
					used_oshi_skill = true
					emit_signal("sent_game_message", tr("MESSAGE_OSHISKILL").format({skillName = Settings.trans(skill[0])}))
				mill(holopower,archive,input)
				currentCard = -1
				please_sync_archive()
				remove_prompt()
		80,81: #Holomem Arts Damage
			var input = new_text.to_int()
			var actualCard = all_cards[currentCard]
			var oppSide = get_parent().opponentSide
			if new_text.is_valid_int() and input > 0:
				emit_signal("sent_game_message", tr("MESSAGE_ARTS_DAMAGE").format(
					{fromZone = find_what_zone(currentCard).name, fromName = actualCard.get_card_name()
					,artName = Settings.trans("%s_ART_%s_NAME" % [actualCard.cardNumber, currentPrompt-80]), damage = input
					,toZone = currentAttacking[0], toName = currentAttacking[1]}))
				remove_prompt()
		
		201: #Draw X
			var input = new_text.to_int()
			if new_text.is_valid_int() and input > 0 and input <= deck.cardList.size():
				draw(input)
				remove_prompt()
				can_undo_shuffle_hand = null
		203: #Mill X
			var input = new_text.to_int()
			if new_text.is_valid_int() and input > 0 and input <= deck.cardList.size():
				mill(deck,archive,input)
				remove_prompt()
				please_sync_archive()
				can_undo_shuffle_hand = null
		297: #Look At X
			var input = new_text.to_int()
			if new_text.is_valid_int() and input > 0 and input <= deck.cardList.size():
				emit_signal("sent_game_message",tr("MESSAGE_DECK_LOOKATX").format({amount = input}))
				remove_prompt()
				deck._update_looking(true,input)
				showLookAt(deck.cardList.slice(0,input))
				currentPrompt = 297
				currentFuda = deck
		
		501: #Holopower X to Archive
			var input = new_text.to_int()
			if new_text.is_valid_int() and input > 0 and input <= holopower.cardList.size():
				mill(holopower,archive,input)
				please_sync_archive()
				remove_prompt()

func _on_zone_clicked(zone_id):
	var actualZoneInfo = zones[zone_id]
	match currentPrompt:
		5: #Move to Back
			emit_signal("sent_game_message",tr("MESSAGE_CARD_BACK").format({fromZone = find_what_zone(currentCard).name, fromName = all_cards[currentCard].get_card_name()}))
			move_card_to_zone(currentCard,actualZoneInfo[0])
			hideZoneSelection()
		7: #Baton Pass
			emit_signal("sent_game_message",tr("MESSAGE_CARD_BATONPASS").format(
				{fromZone = find_what_zone(currentCard).name, fromName = all_cards[currentCard].get_card_name(),
				 toZone = actualZoneInfo[0].name, toName = all_cards[actualZoneInfo[1]].get_card_name()}))
			switch_cards_in_zones(centerZone,actualZoneInfo[0])
			hideZoneSelection()
			used_baton_pass = true
		8: #Switch to Back
			emit_signal("sent_game_message",tr("MESSAGE_CARD_SWITCH").format(
				{fromZone = find_what_zone(currentCard).name, fromName = all_cards[currentCard].get_card_name(),
				 toZone = actualZoneInfo[0].name, toName = all_cards[actualZoneInfo[1]].get_card_name()}))
			switch_cards_in_zones(centerZone,actualZoneInfo[0])
			hideZoneSelection()
		22: #Attach Revealed Support
			var actualCard = all_cards[currentCard]
			var attachTo = find_in_zone(actualZoneInfo[0])
			emit_signal("sent_game_message",tr("MESSAGE_SUPPORT_ATTACH").format(
				{attachName = actualCard.get_card_name(),
				 toZone = actualZoneInfo[0].name, toName = all_cards[attachTo].get_card_name()}))
			actualCard.z_index = 0
			revealed.erase(currentCard)
			all_cards[attachTo].attach(actualCard)
			please_sync_attached_stacked(all_cards[attachTo])
			_move_sfx.rpc()
			hideZoneSelection()
		30: #Attach Cheer
			var actualCard = all_cards[currentCard]
			var attachTo = find_in_zone(actualZoneInfo[0])
			emit_signal("sent_game_message",tr("MESSAGE_CHEER_ATTACH").format(
				{attachName = actualCard.get_card_name(),
				 toZone = actualZoneInfo[0].name, toName = all_cards[attachTo].get_card_name()}))
			all_cards[attachTo].attach(actualCard)
			please_sync_attached_stacked(all_cards[attachTo])
			hideZoneSelection()
			_move_sfx.rpc()
		80,81: #Holomem Arts (called on opponent's side)
			var yourSide = get_parent().yourSide
			yourSide.currentAttacking = [actualZoneInfo[0].name, syncedZones[actualZoneInfo[0].name][1]]
			yourSide.set_prompt(tr("PROMPT_ART_DAMAGE"),20,3)
			hideZoneSelection()
		
		100: #Play
			emit_signal("sent_game_message",tr("MESSAGE_HOLOMEM_PLAY").format({cardName = all_cards[currentCard].get_card_name()}))
			move_card_to_zone(currentCard,actualZoneInfo[0])
			remove_from_hand(currentCard)
			all_cards[currentCard].bloomed_this_turn = true
			hideZoneSelection()
			_place_sfx.rpc()
		101: #Bloom
			var actualCard = all_cards[currentCard]
			bloom_on_zone(actualCard,actualZoneInfo[0])
			remove_from_hand(currentCard)
			please_sync_attached_stacked(actualCard)
			hideZoneSelection()
			_place_sfx.rpc()
		103: #Play Hidden
			move_card_to_zone(currentCard,actualZoneInfo[0])
			remove_from_hand(currentCard,true)
			hideZoneSelection()
			_place_sfx.rpc()
		121: #Attach Support
			var actualCard = all_cards[currentCard]
			var attachTo = find_in_zone(actualZoneInfo[0])
			emit_signal("sent_game_message",tr("MESSAGE_SUPPORT_ATTACH").format(
				{attachName = actualCard.get_card_name(),
				 toZone = actualZoneInfo[0].name, toName = all_cards[attachTo].get_card_name()}))
			actualCard.z_index = 0
			remove_from_hand(currentCard)
			all_cards[attachTo].attach(actualCard)
			please_sync_attached_stacked(all_cards[attachTo])
			hideZoneSelection()
			_place_sfx.rpc()
		
		300: #Attach Cheer
			var actualCard = all_cards[currentCard]
			var attachTo = find_in_zone(actualZoneInfo[0])
			emit_signal("sent_game_message",tr("MESSAGE_CHEER_ATTACH").format(
				{attachName = actualCard.get_card_name(),
				 toZone = actualZoneInfo[0].name, toName = all_cards[attachTo].get_card_name()}))
			actualCard.z_index = 0
			all_cards[attachTo].attach(actualCard)
			please_sync_attached_stacked(all_cards[attachTo])
			hideZoneSelection()
			_move_sfx.rpc()
		
		600: #Play From Deck
			emit_signal("sent_game_message",tr("MESSAGE_DECK_HOLOMEM_PLAY").format({cardName = all_cards[currentCard].get_card_name()}))
			remove_from_fuda(currentCard,deck)
			move_card_to_zone(currentCard,actualZoneInfo[0])
			all_cards[currentCard].bloomed_this_turn = true
			hideZoneSelection()
			can_undo_shuffle_hand = null
			_place_sfx.rpc()
		601: #Bloom From Deck
			remove_from_fuda(currentCard,deck)
			var actualCard = all_cards[currentCard]
			bloom_on_zone(actualCard,actualZoneInfo[0])
			please_sync_attached_stacked(actualCard)
			hideZoneSelection()
			can_undo_shuffle_hand = null
			_place_sfx.rpc()
		602: #Attach Cheer From Deck
			remove_from_fuda(currentCard,cheerDeck)
			var actualCard = all_cards[currentCard]
			var attachTo = find_in_zone(actualZoneInfo[0])
			emit_signal("sent_game_message",tr("MESSAGE_CHEERDECK_CHEER_ATTACH").format(
				{attachName = actualCard.get_card_name(),
				 toZone = actualZoneInfo[0].name, toName = all_cards[attachTo].get_card_name()}))
			all_cards[attachTo].attach(actualCard)
			please_sync_attached_stacked(all_cards[attachTo])
			hideZoneSelection()
			_move_sfx.rpc()
		610: #Play From Archive
			emit_signal("sent_game_message",tr("MESSAGE_ARCHIVE_HOLOMEM_PLAY").format({cardName = all_cards[currentCard].get_card_name()}))
			remove_from_fuda(currentCard,archive)
			move_card_to_zone(currentCard,actualZoneInfo[0])
			all_cards[currentCard].bloomed_this_turn = true
			please_sync_archive()
			hideZoneSelection()
			_place_sfx.rpc()
		611: #Bloom From Archive
			remove_from_fuda(currentCard,archive)
			var actualCard = all_cards[currentCard]
			bloom_on_zone(actualCard,actualZoneInfo[0])
			please_sync_attached_stacked(actualCard)
			please_sync_archive()
			hideZoneSelection()
			_place_sfx.rpc()
		612: #Attach Cheer From Archive
			remove_from_fuda(currentCard,archive)
			var actualCard = all_cards[currentCard]
			var attachTo = find_in_zone(actualZoneInfo[0])
			emit_signal("sent_game_message",tr("MESSAGE_ARCHIVE_CHEER_ATTACH").format(
				{attachName = actualCard.get_card_name(),
				 toZone = actualZoneInfo[0].name, toName = all_cards[attachTo].get_card_name()}))
			all_cards[attachTo].attach(actualCard)
			please_sync_attached_stacked(all_cards[attachTo])
			please_sync_archive()
			hideZoneSelection()
			_move_sfx.rpc()
		622: #Attach Cheer From Attach
			remove_from_attached(currentCard,currentAttached)
			var actualCard = all_cards[currentCard]
			var attachTo = find_in_zone(actualZoneInfo[0])
			emit_signal("sent_game_message",tr("MESSAGE_ATTACHED_CHEER_ATTACH").format(
				{attachName = actualCard.get_card_name(),
				 toZone = actualZoneInfo[0].name, toName = all_cards[attachTo].get_card_name(), 
				 fromZone = find_what_zone(currentAttached.cardID).name, fromName = currentAttached.get_card_name()}))
			all_cards[attachTo].attach(actualCard)
			please_sync_attached_stacked(all_cards[attachTo])
			hideZoneSelection()
			currentPrompt = -1
			currentAttached = null
			_move_sfx.rpc()

func _unhandled_key_input(event):
	if event.is_action_pressed("Draw") and is_multiplayer_authority() and can_do_things and deck.cardList.size() > 0:
		draw(1)

func _on_submit_pressed():
	_on_line_edit_text_submitted(prompt.get_node("Input/LineEdit").text)

@rpc("any_peer","call_local","reliable")
func set_is_turn(value:bool):
	if is_multiplayer_authority():
		is_turn = value
		if is_turn:
				get_parent()._select_step.rpc(1)
		if !preliminary_phase:
			$"CanvasLayer/End Turn".visible = value

@rpc("any_peer","call_local","reliable")
func set_player1(value:bool):
	if is_multiplayer_authority():
		player1 = value
		if player1:
			$CanvasLayer/OpponentLabel/Label.text = tr("TURN_SECOND") #"Opponent Going Second"
			$CanvasLayer/OpponentLabel.visible = true
		else:
			$CanvasLayer/OpponentLabel/Label.text = tr("TURN_FIRST")
			$CanvasLayer/OpponentLabel.visible = true

func end_turn():
	if is_turn:
		emit_signal("sent_game_message",tr("MESSAGE_ENDTURN"))
		step = 1
		first_turn = false
		used_limited = false
		used_baton_pass = false
		used_oshi_skill = false
		can_undo_shuffle_hand = null
		for actualCard in all_cards:
			if actualCard.cardType == "Holomem":
				actualCard.bloomed_this_turn = false
		emit_signal("ended_turn")


func _on_fuda_shuffled():
	_shuffle_sfx.rpc()

func _on_die_result(num):
	emit_signal("sent_game_message",tr("MESSAGE_DIERESULT").format({result = num}))
	_die_sfx.rpc()

@rpc("any_peer","call_local")
func _shuffle_sfx():
	$Audio/Shuffling.play()

@rpc("any_peer","call_local")
func _die_sfx():
	$Audio/Rolling.play()

@rpc("any_peer","call_local")
func _draw_sfx():
	$Audio/Drawing.play()

@rpc("any_peer","call_local")
func _place_sfx():
	$Audio/Placing.play()

@rpc("any_peer","call_local")
func _move_sfx():
	$Audio/Moving.play()


