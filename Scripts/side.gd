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
@onready var cardLayers = {"Cheer":$Cards/Cheer, "Attached":$Cards/Attached, "Main":$Cards/Main, "Above":$Cards/Above}

@onready var deck = $SubViewportContainer/SubViewport/Node3D/DECK
@onready var cheerDeck = $SubViewportContainer/SubViewport/Node3D/CHEERDECK
@onready var archive = $SubViewportContainer/SubViewport/Node3D/ARCHIVE
@onready var holopower = $SubViewportContainer/SubViewport/Node3D/HOLOPOWER
@onready var fuda_list = [deck, cheerDeck, archive, holopower]
@onready var die = $SubViewportContainer/SubViewport/Node3D/Die
@onready var spMarker = $SPmarker

var currentCard = -1
var currentFuda = null
var currentAttached = null
var currentPrompt = -1
var currentAttacking = ["", ""]
var playing = null

@onready var zones = [[centerZone,-1], [collabZone,-1], [backZone1,-1], [backZone2,-1], [backZone3,-1], [backZone4,-1], [backZone5,-1], [backZone6,-1]]

const card = preload("res://Scenes/card.tscn")
const betterButton = preload("res://Scenes/better_texture_button.tscn")

var all_cards = {}
var oshiCard
var hand = []
var life = []
var revealed = []

@export var oshi:Array
@export var deckList:Array
@export var cheerDeckList:Array

@export var defaultCheer:CompressedTexture2D = preload("res://cheerBack.png")
@export var defaultMain:CompressedTexture2D = preload("res://holoBack.png")
@export var mainSleeve:PackedByteArray
@export var cheerSleeve:PackedByteArray
@export var oshiSleeve:PackedByteArray
var mainBack
var cheerBack
var oshiBack
@export var playmatBuffer:PackedByteArray
@export var diceBuffer:PackedByteArray

@export var preliminary_phase = true
var preliminary_holomem_in_center = false
@export var can_do_things = false
var fake_cards_on_stage = []
var fuda_opponent_looking_at = null

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

@export var is_your_side = false
@export var player_id : String
@export var player_name : String

@export var is_front = false
@export var side_info = {}

var losing_reason = ""

signal ended_turn
signal made_turn_choice(choice)
signal rps(choice)
signal mulligan_done
signal ready_decided

signal card_info_set(top_card, card_to_show)
signal card_info_clear

signal entered_list
signal exited_list

# Called when the node enters the scene tree for the first time.
func _ready():
	tr("DECK")
	tr("CHEERDECK")
	tr("ARCHIVE")
	tr("HOLOPOWER")
	# for POT generation
	
	if is_your_side or is_front:
		holopower.count.position += Vector3(0.3,0,4.6)
		holopower.looking.position += Vector3(3,0,0)
	else:
		position = Vector2(0,-1044)
		rotation = -3.141
		$SubViewportContainer/SubViewport/Node3D.position += Vector3(1000,0,1000)
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
	
	if is_your_side:
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
	
	if oshiSleeve.is_empty():
		oshiBack = defaultCheer.get_image()
	else:
		var image = Image.new()
		image.load_webp_from_buffer(oshiSleeve)
		oshiBack = image
	if is_your_side:
		oshiCard = create_card(oshi[0],oshi[1],oshiBack)
	elif ("oshi" in side_info and side_info["oshi"]):
		oshiCard = get_real_card(side_info["oshi"], oshiBack)
	else:
		oshiCard = create_fake_card(oshiBack)
		oshiCard.flipDown()
	oshiCard.position = Vector2(430,-223)
	
	if mainSleeve.is_empty():
		mainBack = defaultMain.get_image()
	else:
		var image = Image.new()
		image.load_webp_from_buffer(mainSleeve)
		mainBack = image
	if is_your_side:
		for info in deckList:
			for i in range(info[1]):
				var newCard1 = create_card(info[0],info[2],mainBack)
				deck.cardList.append(newCard1)
				newCard1.visible = false
				newCard1.z_index = 1
	else:
		var total_main = 50
		if "deck" in side_info:
			total_main = int(side_info["deck"])
		for i in range(total_main):
			var newCard1 = create_fake_card(mainBack)
			deck.cardList.append(newCard1)
			newCard1.visible = false
	
	if cheerSleeve.is_empty():
		cheerBack = defaultCheer.get_image()
	else:
		var image = Image.new()
		image.load_webp_from_buffer(cheerSleeve)
		cheerBack = image
	if is_your_side:
		for info in cheerDeckList:
			for i in range(info[1]):
				var newCard1 = create_card(info[0],info[2],cheerBack)
				cheerDeck.cardList.append(newCard1)
				newCard1.visible = false
	else:
		var total_cheer = 20
		if "cheerDeck" in side_info:
			total_cheer = int(side_info["cheerDeck"])
		for i in range(total_cheer):
			var newCard1 = create_fake_card(cheerBack)
			cheerDeck.cardList.append(newCard1)
			newCard1.visible = false
	
	if "holopower" in side_info:
		for i in range(int(side_info["holopower"])):
			var newCard1 = create_fake_card(cheerBack)
			holopower.cardList.append(newCard1)
			newCard1.visible = false
	if "archive" in side_info:
		for card_info in side_info["archive"]:
			var newCard1 = get_real_card(card_info, cheerBack if card_info.cardType == "Cheer" else mainBack)
			archive.cardList.append(newCard1)
			newCard1.visible = false
	if "life" in side_info:
		for index in range(int(side_info["life"])):
			var newLife = create_fake_card(cheerBack)
			life.append(newLife)
			if index > 0:
				move_behind(newLife,life[index-1])
			newLife.trulyHide()
			newLife.position = Vector2(-960,-145-(53*(6-int(side_info["life"])+index)))
			newLife.rest()
			newLife.visible = true
	if "hand" in side_info:
		for index in range(int(side_info["hand"])):
			add_fake_to_hand()
	if "zones" in side_info:
		for zone in side_info["zones"]:
			move_fake_card_to_zone(side_info["zones"][zone], $Zones.get_node(zone), side_info["zones"][zone]==null)
	if "revealed" in side_info:
		for card_to_reveal in side_info["revealed"]:
			reveal_fake_card(card_to_reveal)
	if "playing" in side_info and side_info["playing"]:
		play_fake_card(side_info["playing"])
	
	deck.update_size()
	deck.update_back(mainBack)
	cheerDeck.update_size()
	cheerDeck.update_back(cheerBack)
	archive.update_size()
	holopower.update_size()
	holopower.update_back(mainBack)
	
	if side_info == {}:
		deck.shuffle()
		cheerDeck.shuffle()
	
	move_child($Zones,-1)
	
	if is_your_side:
		$CanvasLayer/Question.visible = true
		$SubViewportContainer/SubViewport/Node3D/Die.is_your_die = true

#Yes I know I can bind arguments to the signal connection
#Godot has been randomly removing those connections though
#So here ;jkHJV LK.SDFACVW, BGJAEQSmnhjmn ,v adeswkm ,mabdfnnv cdxzvcmnvxcdmnxz fcbv 
#Sorry angy
func _rps_rock():
	_rps(0)
func _rps_paper():
	_rps(1)
func _rps_scissors():
	_rps(2)
func _go_first():
	_made_turn_choice(true)
func _go_second():
	_made_turn_choice(false)

func _rps(choice):
	$CanvasLayer/Question/Label.text = tr("RPS_WAIT")
	$CanvasLayer/Question/RPS/Rock.disabled = true
	$CanvasLayer/Question/RPS/Paper.disabled = true
	$CanvasLayer/Question/RPS/Scissors.disabled = true
	emit_signal("rps",choice)

func specialRestart():
	$CanvasLayer/Question/Label.text = tr("RPS_TIED")
	$CanvasLayer/Question/RPS/Rock.disabled = false
	$CanvasLayer/Question/RPS/Paper.disabled = false
	$CanvasLayer/Question/RPS/Scissors.disabled = false

func rps_end():
	$CanvasLayer/Question.visible = false
	$CanvasLayer/Question/RPS.visible = false
	oshiCard.visible = true

func _made_turn_choice(choice:bool):
	$"CanvasLayer/Go First".visible = false
	$"CanvasLayer/Go Second".visible = false
	emit_signal("made_turn_choice",choice)

func _show_turn_choice():
	$"CanvasLayer/Go First".visible = true
	$"CanvasLayer/Go Second".visible = true

func _mulligan_decision(forced=false):
	$CanvasLayer/Question.visible = true
	$CanvasLayer/Question/Label.text = tr("MULLIGAN_QUESTION")
	$CanvasLayer/Question/Yes.visible = true
	$CanvasLayer/Question/No.visible = true
	$CanvasLayer/Question/OK.visible = false
	$CanvasLayer/Question.visible = true
	if forced:
		$CanvasLayer/Question/Yes.visible = false
		$CanvasLayer/Question/No.visible = false
		$CanvasLayer/Question/OK.visible = true
		$CanvasLayer/Question/Label.text = tr("MULLIGAN_FORCED")
	else:
		$CanvasLayer/Question/No.disabled = false

func yes_mulligan():
	send_command("Yes Mulligan")
	$CanvasLayer/Question/Yes.visible = false
	$CanvasLayer/Question/No.visible = false
	$CanvasLayer/Question/OK.visible = false

func game_loss():
	$CanvasLayer/Question/Label.text = tr("LOSS")
	$CanvasLayer/Question/OK.visible = false

func no_mulligan():
	send_command("No Mulligan")
	$CanvasLayer/Question/Yes.visible = false
	$CanvasLayer/Question/No.visible = false
	$CanvasLayer/Question/OK.visible = false

func wait_mulligan():
	$CanvasLayer/Question/Label.text = tr('MULLIGAN_WAIT')
	$CanvasLayer/Question/Yes.visible = false
	$CanvasLayer/Question/No.visible = false
	$CanvasLayer/Question/OK.visible = false

func specialStart3(fmc):
	if fmc.size() > 0:
		$CanvasLayer/OpponentLabel/MulliganWarning.visible = true
		var look_at_mulliganed = []
		for card_info in fmc:
			if card_info == null:
				look_at_mulliganed.append(null)
			else:
				look_at_mulliganed.append(get_parent().opponentSide.get_real_card(card_info, mainBack, true))
		showLookAt(look_at_mulliganed)
	
	$CanvasLayer/Question.visible = false
	$CanvasLayer/Ready.visible = true
	can_do_things = true

func _call_ready():
	send_command("Ready")
	$CanvasLayer/Ready.disabled = true
	$CanvasLayer/Ready.text = tr("READY_WAIT")

func specialStart4(life_info,ist):
	oshiCard.flipUp()
	
	for zoneInfo in zones:
		if zoneInfo[1] != -1:
			all_cards[zoneInfo[1]].flipUp()
	
	preliminary_phase = false
	$CanvasLayer/Ready.visible = false
	$CanvasLayer/OpponentLabel.visible = false
	$"CanvasLayer/End Turn".visible = is_turn
	
	for index in range(len(life_info)):
		var newLife = all_cards[int(life_info[index])]
		cheerDeck.cardList.erase(newLife)
		life.append(newLife)
		if index > 0:
			move_behind(newLife,life[index-1])
		newLife.trulyHide()
		newLife.position = Vector2(-960,-145-(53*(6-oshiCard.life+index)))
		newLife.rest()
		newLife.visible = true
	
	cheerDeck.update_size()
	
	get_parent()._enable_steps()

func specialStart4_fake(oshi_info, zone_info):
	oshiCard.queue_free()
	oshiCard = get_real_card(oshi_info, oshiBack)
	oshiCard.position = Vector2(430,-223)
	
	for fake in fake_cards_on_stage:
		fake.queue_free()
	
	for zone in zone_info:
		var newCard = get_real_card(zone_info[zone],mainBack)
		move_card_to_zone(newCard.cardID,$Zones.get_node(zone))
	
	preliminary_phase = false
	$CanvasLayer/Ready.visible = false
	$CanvasLayer/OpponentLabel.visible = false
	
	for i in range(oshiCard.life):
		var newLife = cheerDeck.cardList.pop_front()
		life.append(newLife)
		if i > 0:
			move_behind(newLife,life[i-1])
		newLife.trulyHide()
		newLife.position = Vector2(-960,-145-(53*(6-oshiCard.life+i)))
		newLife.rest()
		newLife.visible = true
	
	cheerDeck.update_size()


func create_card(number,art_code,back):
	var new_id = all_cards.size()
	var newCard = card.instantiate()
	newCard.name = "Card" + str(new_id)
	newCard.setup_info(number,art_code,back)
	if newCard.cardType == "Cheer":
		cardLayers["Cheer"].add_child(newCard,true)
	else:
		cardLayers["Main"].add_child(newCard,true)
	newCard.cardID = new_id
	newCard.attachedTo = new_id
	newCard.card_clicked.connect(_on_card_clicked)
	newCard.card_right_clicked.connect(_on_card_right_clicked)
	newCard.card_mouse_over.connect(update_info)
	newCard.move_behind_request.connect(move_behind_ids)
	newCard.accept_damage.connect(_on_accept_damage)
	newCard.reject_damage.connect(_on_reject_damage)
	all_cards[new_id] = newCard
	newCard.position = Vector2(1000,1000)
	return newCard

func create_fake_card(back):
	var newCard = card.instantiate()
	cardLayers["Main"].add_child(newCard,true)
	newCard.name = "Card"
	newCard.fake_card = true
	newCard.updateBack(ImageTexture.create_from_image(back))
	newCard.cardID = -1
	newCard.attachedTo = -1
	newCard.position = Vector2(1000,1000)
	move_child($Zones,-1)
	return newCard

func get_real_card(card_dict, back, temp=false):
	var new_id = int(card_dict.cardID)
	if new_id in all_cards:
		return all_cards[new_id]
	else:
		var new_number = card_dict.cardNumber
		var new_art = int(card_dict.artIndex)
		var newCard = card.instantiate()
		newCard.name = "Card" + str(new_id)
		newCard.setup_info(new_number,new_art,back)
		if newCard.cardType == "Cheer":
			cardLayers["Cheer"].add_child(newCard,true)
		else:
			cardLayers["Main"].add_child(newCard,true)
		newCard.cardID = new_id
		newCard.temporary = temp
		newCard.card_clicked.connect(_on_card_clicked)
		newCard.card_right_clicked.connect(_on_card_right_clicked)
		newCard.card_mouse_over.connect(update_info)
		newCard.move_behind_request.connect(move_behind_ids)
		newCard.attachedTo = int(card_dict.attachedTo)
		if card_dict.rested:
			newCard.rest()
		newCard.faceDown = card_dict.faceDown
		newCard.trulyHidden = card_dict.trulyHidden
		newCard.onstage = card_dict.onstage
		if card_dict.cardType == "Holomem":
			newCard.damage = int(card_dict.damage)
			newCard.extra_hp = int(card_dict.extra_hp)
		all_cards[new_id] = newCard
		newCard.position = Vector2(1000,1000)
		move_child($Zones,-1)
		return newCard

func reveal_card(card_id):
	var actualCard = all_cards[card_id]
	actualCard.position = Vector2(300,100*revealed.size() - 400)
	actualCard.reparent(cardLayers["Above"],true)
	actualCard.visible = true
	revealed.append(card_id)
	for i in range(revealed.size()):
		if i > 0:
			move_behind(all_cards[revealed[-i-1]],all_cards[revealed[-i]])
	_place_sfx()

func reveal_fake_card(card_info):
	var fake_card = get_real_card(card_info, mainBack)
	reveal_card(fake_card.cardID)

func play_card(card_id):
	var actualCard = all_cards[card_id]
	if actualCard.limited:
		used_limited = true
	actualCard.reparent(cardLayers["Above"],true)
	actualCard.position = Vector2(0,0)
	playing = card_id
	_place_sfx()

func play_fake_card(card_info):
	var fake_card = get_real_card(card_info, mainBack)
	play_card(fake_card.cardID)

func reveal_cheer(card_id, show_zones=true):
	var actualCard = all_cards[card_id]
	actualCard.visible = true
	actualCard.reparent(cardLayers["Above"],true)
	actualCard.position = Vector2(-1250,-300)
	_move_sfx()
	if show_zones:
		var possibleZones = all_occupied_zones()
		showZoneSelection(possibleZones,false)
		currentCard = card_id
		currentPrompt = 300

func reveal_fake_cheer(card_info):
	var fake_card = get_real_card(card_info, cheerBack)
	reveal_cheer(fake_card.cardID, false)

func reveal_fake_life(card_info):
	var actualCard = get_real_card(card_info, cheerBack)
	actualCard.reparent(cardLayers["Above"],true)
	var oldCard = life.pop_front()
	actualCard.position = oldCard.position
	oldCard.queue_free()

func add_to_life(card_id):
	var actualCard = all_cards[card_id]
	if life.size() < 6 and actualCard.cardType == "Cheer":
		life.insert(0, actualCard)
		actualCard.reparent(cardLayers["Cheer"],true)
		actualCard.trulyHide()
		actualCard.position = Vector2(-960,-145-(53*(6-life.size())))
		actualCard.rest()
		actualCard.visible = true
		for i in range(life.size()):
			if i > 0:
				move_behind(life[i],life[i-1])

func add_fake_to_life():
	if life.size() < 6:
		var actualCard = create_fake_card(cheerBack)
		life.insert(0, actualCard)
		actualCard.trulyHide()
		actualCard.position = Vector2(-960,-145-(53*(6-life.size())))
		actualCard.rest()
		actualCard.visible = true
		for i in range(life.size()):
			if i > 0:
				move_behind(life[i],life[i-1])

func update_hand():
	var max_offset = clamp(125 * (hand.size() - 1),0,1250)
	var each_offset = 250
	if hand.size() > 1:
		each_offset = clamp(2*max_offset/(hand.size()-1),0,250)
	for i in range(hand.size()):
		hand[i].position = Vector2(-max_offset - 125,750) + (i * Vector2(each_offset,0))
		hand[i].visible = true
		if i > 0:
			move_behind(hand[-i-1],hand[-i])

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

func remove_old_card(old_card,leavingField = false):
	if leavingField:
		var actualCard = all_cards[old_card]
		if actualCard.cardType == "Cheer":
			actualCard.reparent(cardLayers["Cheer"],true)
		else:
			actualCard.reparent(cardLayers["Main"],true)
		actualCard.unrest()
		for att in actualCard.attached:
			att.attachedTo = att.cardID
			remove_old_card(att.cardID,true)
		for oto in actualCard.onTopOf:
			oto.attachedTo = oto.cardID
			remove_old_card(oto.cardID,true)
		actualCard.attached = []
		actualCard.onTopOf = []
		actualCard._on_reject_pressed()
		actualCard.onstage = false
		actualCard.clear_damage()
		actualCard.clear_extra_hp()
		if old_card in revealed:
			revealed.erase(old_card)
		if old_card == playing:
			playing = null
		actualCard.position = Vector2(1000,2000)
	
	var found_holomem_on_stage = false
	var found_old_on_stage = false
	for index in range(zones.size()):
		if zones[index][1] == old_card:
			zones[index][1] = -1
			found_old_on_stage = true
		elif zones[index][1] != -1:
			found_holomem_on_stage = true
	
	if found_old_on_stage and leavingField and !found_holomem_on_stage:
		_show_loss_consent("EMPTYSTAGE")

func remove_from_hand(old_card, hidden=false):
	for index in range(hand.size()):
		if hand[index].cardID == old_card:
			if !hidden:
				hand[index].flipUp()
			hand[index].reparent(cardLayers["Main"],true)
			hand.remove_at(index)
			break
	update_hand()

func remove_fake_from_hand():
	var old_card = hand.pop_front()
	if old_card:
		old_card.queue_free()
	update_hand()

func add_to_hand(new_card):
	var cardToGo = all_cards[new_card]
	
	if cardToGo.onstage:
		remove_old_card(new_card, true)
	
	cardToGo.reparent(cardLayers["Above"],true)
	
	hand.append(cardToGo)
	_draw_sfx()
	update_hand()

func add_fake_to_hand():
	var cardToGo = create_fake_card(mainBack)
	cardToGo.reparent(cardLayers["Above"],true)
	cardToGo.flipDown()
	
	hand.append(cardToGo)
	_draw_sfx()
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
	
	if fuda == deck:
		can_undo_shuffle_hand = null
	
	if all_cards[card_id].cardType == "Holomem":
		all_cards[card_id].bloomed_this_turn = true
	
	fuda.update_size()

func remove_fake_from_fuda(fuda, card_info):
	if fuda == archive and card_info:
		var cardToGo = get_real_card(card_info, cheerBack if card_info.cardType == "Cheer" else mainBack)
		remove_from_card_list(cardToGo.cardID, archive.cardList)
	else:
		fuda.cardList.pop_front().queue_free()
	fuda.update_size()

func remove_from_attached(card_id,attached):
	var actualCard = all_cards[card_id]
	if actualCard.cardType == "Cheer":
		actualCard.reparent(cardLayers["Cheer"],true)
	else:
		actualCard.reparent(cardLayers["Main"],true)
		
	if actualCard in attached.attached:
		remove_from_card_list(card_id,attached.attached)
		actualCard.attachedTo = card_id
		attached.update_attached()
	elif actualCard in attached.onTopOf:
		remove_from_card_list(card_id,attached.onTopOf)

func remove_fake_from_attached(card_id, attached_id):
	if card_id in all_cards and attached_id in all_cards:
		remove_from_attached(card_id, all_cards[attached_id])
		all_cards[card_id].position = Vector2(1000,1000)

func add_to_card_list(card_id,list_of_cards,bottom=false):
	var new_position = 0
	if bottom:
		new_position = list_of_cards.size()
	var cardToGo = all_cards[card_id]
	
	cardToGo.attached.reverse()
	cardToGo.onTopOf.reverse()
	for newCard in cardToGo.attached:
		#add_to_card_list(newCard.cardID,list_of_cards,bottom)
		newCard.attachedTo = newCard.cardID
	for newCard in cardToGo.onTopOf:
		#add_to_card_list(newCard.cardID,list_of_cards,bottom)
		newCard.attachedTo = newCard.cardID
	
	list_of_cards.insert(new_position,cardToGo)
	cardToGo.position = Vector2(1000,1000)
	cardToGo.visible = false
	_move_sfx()

func add_to_fuda(card_id,fuda,bottom=false):
	var actualCard = all_cards[card_id]
	if actualCard.cardType == "Cheer":
		actualCard.reparent(cardLayers["Cheer"],true)
	else:
		actualCard.reparent(cardLayers["Main"],true)
	add_to_card_list(card_id,fuda.cardList,bottom)
	
	fuda.update_size()

func add_fake_to_fuda(fuda, moved_card = null):
	var cardToGo
	if fuda == archive and moved_card:
		cardToGo = get_real_card(moved_card, cheerBack if moved_card.cardType == "Cheer" else mainBack)
		add_to_fuda(cardToGo.cardID, archive)
	else:
		cardToGo = create_fake_card(cheerBack if fuda == cheerDeck else mainBack)
		fuda.cardList.append(cardToGo)
		cardToGo.position = Vector2(1000,1000)
		cardToGo.visible = false
		_move_sfx()
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
		_move_sfx()
	else:
		_place_sfx()
	
	set_zone_card(zone,card_id)

func move_fake_card_to_zone(card_info, zone, facedown=false):
	var actualCard
	if facedown:
		actualCard = create_fake_card(mainBack)
		actualCard.flipDown()
		actualCard.move_to(zone.position)
		actualCard.onstage = true
		fake_cards_on_stage.append(actualCard)
		_place_sfx()
	else:
		actualCard = get_real_card(card_info, mainBack)
		
		actualCard.move_to(zone.position)
		actualCard.onstage = true
		var card_id = actualCard.cardID
		
		if find_what_zone(card_id):
			remove_old_card(card_id)
			_move_sfx()
		else:
			_place_sfx()
		
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
	_move_sfx()
	_move_sfx()
	
	set_zone_card(zone_1,card2.cardID)
	set_zone_card(zone_2,card1.cardID)

func bloom_on_zone(card_to_bloom, zone_to_bloom):
	var bloomee = all_cards[find_in_zone(zone_to_bloom)]
	card_to_bloom.visible = true
	card_to_bloom.bloom(bloomee)
	set_zone_card(zone_to_bloom,card_to_bloom.cardID)
	_place_sfx()

func bloom_fake_on_zone(fake_card_to_bloom, zone_to_bloom):
	var card_to_bloom = get_real_card(fake_card_to_bloom, mainBack)
	card_to_bloom.visible = true
	var bloomee = all_cards[find_in_zone(zone_to_bloom)]
	card_to_bloom.bloom(bloomee)
	set_zone_card(zone_to_bloom,card_to_bloom.cardID)
	_place_sfx()

func unbloom_on_zone(card_to_unbloom):
	var unbloomee = all_cards[card_to_unbloom]
	var underCard = unbloomee.unbloom()
	if underCard:
		set_zone_card(find_what_zone(unbloomee.cardID),underCard.cardID)
	_move_sfx()

func unbloom_fake_on_zone(fake_card_to_unbloom):
	var unbloomee = all_cards[fake_card_to_unbloom]
	var underCard = unbloomee.unbloom()
	if underCard:
		set_zone_card(find_what_zone(unbloomee.cardID),underCard.cardID)
	_move_sfx()

func attach_card(attachee, attach_to):
	var actualCard = all_cards[attachee]
	actualCard.reparent(cardLayers["Attached"],true)
	actualCard.z_index = 0
	var attachTo = all_cards[attach_to]
	attachTo.attach(actualCard)
	revealed.erase(attachee)
	_move_sfx()

func attach_fake_card(attachee_info, attach_to_info):
	var attachee = get_real_card(attachee_info, cheerBack if attachee_info.cardType == "Cheer" else mainBack)
	var attach_to = get_real_card(attach_to_info, mainBack)
	attach_card(attachee.cardID, attach_to.cardID)

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
		if actualCard.temporary:
			newButton.mouse_entered.connect(get_parent().opponentSide.update_info.bind(actualCard.cardID))
		else:
			newButton.mouse_entered.connect(update_info.bind(actualCard.cardID))
		lookAtList.add_child(newButton)
		newButton.scale = Vector2(0.7,0.7)
		newButton.position = Vector2(210*i+5,5)
	
	for actualCard in list_of_cards:
		if actualCard and actualCard.temporary:
			actualCard.position = Vector2(1000,1000)
	
	lookAtList.custom_minimum_size = Vector2(list_of_cards.size()*220 + 10, 0)
	lookAt.get_h_scroll_bar().custom_minimum_size.y = 30
	lookAt.scroll_horizontal = 0
	
	if lookAtList.get_child_count() >0:
		lookAt.visible = true
		cancel.visible = true
		emit_signal("entered_list")
	else:
		hideLookAt()

func showLookAtIDS(list_of_ids):
	var list_of_cards = []
	for id in list_of_ids:
		list_of_cards.append(all_cards[int(id)])
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
		if currentFuda in [deck, cheerDeck] and currentPrompt not in [297, 397]:
			currentFuda.shuffle()
	elif currentPrompt == 297:
		deck._update_looking(false)
	
	for newButton in lookAtList.get_children():
		newButton.queue_free()
	lookAt.visible = false
	cancel.visible = false
	$CanvasLayer/OpponentLabel/MulliganWarning.visible = false
	#emit_signal("exited_list")
	send_command("Stop Look At")
	if endOfAction:
		currentPrompt = -1
		currentFuda = null
		currentAttached = null

func flipSPdown():
	spMarker.texture = load("res://SPdown.png")

func showZoneSelection(zones_list,show_cancel=true):
	for zone in zones_list:
		var card_in_zone = find_in_zone(zone)
		if card_in_zone != -1 and all_cards[card_in_zone].rested:
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
	if yourSide:
		yourSide.hideLookAt()
		yourSide.remove_prompt()
		yourSide.hideZoneSelection()
	hideLookAt()
	remove_prompt()
	hideZoneSelection()
	$CanvasLayer/Question.visible = false

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

func update_info(card_id):
	var actualCard = all_cards[card_id]
	var topCard = all_cards[actualCard.attachedTo]
	if !actualCard.trulyHidden and (is_your_side or !actualCard.faceDown):
		emit_signal("card_info_set",topCard,actualCard)

func clear_info():
	emit_signal("card_info_clear")

func move_behind(card_1,card_2):
	var possible_parent = card_1.get_parent()
	if possible_parent and card_2.get_parent() == possible_parent:
		#There was a strange bug when adding the layering system
		#Turns out just setting the id to card_2's index-1 fails spectacularly when
		#	said index is 0
		possible_parent.move_child(card_1,max(card_2.get_index()-1,0))

func move_behind_ids(card_id_1,card_id_2):
	var card_1 = all_cards[card_id_1]
	var card_2 = all_cards[card_id_2]
	move_behind(card_1,card_2)

func _on_card_clicked(card_id : int) -> void:
	#Oh boy
	#This is called whenever you click on a card
	#card_id is the index in all_cards of the clicked card
	#If you click your opponent's card, this gets called on your local copy of the opponent's side
	#The code will go through, determine what options ought be included, and add them to the popup
	
	if currentPrompt != -1 or (!can_do_things and is_your_side):
		return
	
	reset_popup()
	currentCard = card_id
	
	var actualCard = all_cards[currentCard]
	if not actualCard in hand:
		actualCard.showNotice()
		send_command("Click Notification",{"player_id":player_id,"card_id":currentCard})
	
	if !is_your_side:
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
			if preliminary_holomem_in_center and all_occupied_zones().size() < 6:
				popup.add_item(tr("CARD_HOLOMEM_PLAY_BACKHIDDEN"), 103)
	else:
		match actualCard.cardType:
			"Holomem":
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
						if !actualCard.rested and currentZone in [centerZone, collabZone] and !(first_turn and player1):
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
						popup.add_item(Settings.trans(skill[0]) + sp_string + "-" + cost_string,71 if skill[2] else 70)
					if ((!skill[2] and used_oshi_skill) or (skill[2] and used_sp_oshi_skill)) and canPayCost:
						popup.add_item(Settings.trans(skill[0]) + sp_string + " (again) -" + cost_string,71 if skill[2] else 70)
		
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
				popup.add_item(tr("CARD_HAND_REVEAL"),114)
			elif find_what_zone(currentCard):
				popup.add_item(tr("CARD_STAGE_ARCHIVE"),2)
				if actualCard.attached.size() == 0:
					popup.add_item(tr("CARD_STAGE_HAND"),3)
				if find_in_zone(collabZone) == -1 and find_what_zone(currentCard) != centerZone:
					popup.add_item(tr("CARD_HOLOMEM_MOVE_COLLAB"), 9)
				if find_what_zone(currentCard) == centerZone and all_occupied_zones(true).size() > 0:
					popup.add_item(tr("CARD_HOLOMEM_SWITCH"), 8)
			elif currentCard in revealed:
				popup.add_item(tr("CARD_REVEALED_HAND"),21)
				if actualCard.cardType == "Support" and actualCard.supportType in ["Tool","Mascot","Fan"] and all_occupied_zones().size() > 0:
					popup.add_item(tr("CARD_REVEALED_ATTACH"),22)
				popup.add_separator()
				popup.add_item(tr("CARD_REVEALED_TOPDECK"),23)
				popup.add_item(tr("CARD_REVEALED_BOTTOMDECK"),24)
				popup.add_item(tr("CARD_REVEALED_ARCHIVE"),25)
				popup.add_item(tr("CARD_REVEALED_HOLOPOWER"),26)
				popup.add_item(tr("CARD_REVEALED_BOTTOMHOLOPOWER"),27)
	
	show_popup()

func _on_card_right_clicked(card_id):
	if preliminary_phase or currentPrompt != -1:
		return
	
	if is_your_side and can_do_things and find_what_zone(card_id):
		var actualCard = all_cards[card_id]
		if actualCard.rested:
			send_command("Popup Command", {"currentCard":card_id, "command_id":1})
		else:
			send_command("Popup Command", {"currentCard":card_id, "command_id":0})

func _on_deck_clicked():
	reset_popup()
	
	if preliminary_phase or currentPrompt != -1:
		return
	
	if is_your_side and can_do_things:
		
		popup.add_item(tr("DECK_DRAW"),200)
		popup.add_item(tr("DECK_DRAWX"),201)
		popup.add_item(tr("DECK_ARCHIVE"),202)
		popup.add_item(tr("DECK_ARCHIVEX"),203)
		popup.add_item(tr("DECK_HOLOPOWER"),204)
		if revealed.size() < 10:
			popup.add_item(tr("DECK_REVEAL"),205)
		
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
		
		if !get_parent().rps:
			popup.add_separator()
			popup.add_item(tr("DECK_RPS"), 296)
		
		popup.add_separator()
		popup.add_item(tr("FORFEIT"), 999)
		
	show_popup()

func _on_cheer_deck_clicked():
	reset_popup()
	
	if preliminary_phase or currentPrompt != -1:
		return
	
	if is_your_side and can_do_things:
		if all_occupied_zones().size() > 0:
			popup.add_item(tr("CHEERDECK_REVEAL"),300)
			popup.add_separator()
		
		popup.add_item(tr("CHEERDECK_LOOKX"),397)
		popup.add_item(tr("CHEERDECK_SEARCH"),398)
		popup.add_item(tr("CHEERDECK_SHUFFLE"),399)
		
	show_popup()

func _on_archive_clicked():
	reset_popup()
	
	if preliminary_phase or currentPrompt != -1:
		return
	
	popup.add_item(tr("ARCHIVE_SEARCH"),498)
	
	if is_your_side and can_do_things and hand.size() > 0:
		popup.add_separator()
		popup.add_item(tr("ARCHIVE_HAND_ALL"),410)
		
	show_popup()

func _on_holopower_clicked():
	reset_popup()
	
	if preliminary_phase or currentPrompt != -1:
		return
	
	if is_your_side and can_do_things:
		popup.add_item(tr("HOLOPOWER_ARCHIVE"),500)
		popup.add_item(tr("HOLOPOWER_ARCHIVEX"),501)
		
		if revealed.size() < 10:
			popup.add_item(tr("HOLOPOWER_REVEAL"),505)
		
		popup.add_separator()
		
		popup.add_item(tr("HOLOPOWER_DECK"), 510)
		
		popup.add_separator()
		
		popup.add_item(tr("HOLOPOWER_SEARCH"),598)
		popup.add_item(tr("HOLOPOWER_SHUFFLE"),599)
		
	show_popup()

func _on_list_card_clicked(card_id):
	if preliminary_phase or currentPrompt == -1 or !is_your_side:
		return
	
	reset_popup()
	currentCard = card_id
	
	var actualCard = all_cards[currentCard]
	var fullFuda = true
	if currentPrompt in [297, 397]:
		fullFuda = false
	
	#Requires zone target and thus must be broken up by fuda
	match actualCard.cardType:
		"Holomem":
			if first_unoccupied_back_zone() and actualCard.level < 1 and is_turn and all_occupied_zones().size() < 6:
				if currentFuda == deck:
					popup.add_item(tr("LIST_DECK_HOLOMEM_PLAY"),600)
				elif currentFuda == archive:
					popup.add_item(tr("LIST_ARCHIVE_HOLOMEM_PLAY"),610)
			if is_turn and !first_turn:
				var bloomable = all_bloomable_zones(actualCard)
				if bloomable[Settings.bloomCode.OK].size() > 0:
					if currentFuda == deck:
						popup.add_item(tr("LIST_DECK_HOLOMEM_BLOOM"),601)
					elif currentFuda == archive:
						popup.add_item(tr("LIST_ARCHIVE_HOLOMEM_BLOOM"),611)
				if bloomable[Settings.bloomCode.Instant].size() > 0:
					if currentFuda == deck:
						popup.add_item(tr("LIST_DECK_HOLOMEM_BLOOM_FAST"),604)
					elif currentFuda == archive:
						popup.add_item(tr("LIST_ARCHIVE_HOLOMEM_BLOOM_FAST"),614)
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
	if currentFuda:
		send_command("Popup From Fuda Command",{"currentCard":currentCard, "command_id":id, "currentFuda":fuda_list.find(currentFuda)})
	elif currentAttached:
		send_command("Popup From Attached Command",{"currentCard":currentCard, "command_id":id, "currentAttached":currentAttached.cardID})
	else:
		send_command("Popup Command", {"currentCard":currentCard, "command_id":id})
	
	match id:
		
		5: #Move to Back
			showZoneSelection(all_unoccupied_back_zones())
			currentPrompt = 5
		
		7: #Baton Pass
			showZoneSelection(all_occupied_zones(true))
			currentPrompt = 7
		8: #Switch to Back
			showZoneSelection(all_occupied_zones(true))
			currentPrompt = 8
		
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
		
		22: #Attach Revealed Support
			var possibleZones = all_occupied_zones()
			showZoneSelection(possibleZones)
			currentPrompt = 22
		30: #Reveal and Attach Life
			if life.size() <= 1:
				_show_loss_consent("LIFE")
			var possibleZones = all_occupied_zones()
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
		70: #Oshi Skill
			var skill = all_cards[currentCard].oshi_skills[0]
			if skill[1] >= 0:
				used_oshi_skill = true
				currentCard = -1
			else:
				set_prompt(tr("PROMPT_OSHICOST") + "\nX=",3)
				currentPrompt = id
		71: #SP Oshi Skill
			var skill = all_cards[currentCard].oshi_skills[1]
			if skill[1] >= 0:
				used_sp_oshi_skill = true
				flipSPdown()
				currentCard = -1
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
			preliminary_holomem_in_center = true
			$CanvasLayer/Ready.disabled = false
		103: #Play Hidden to Back
			var possibleZones = all_unoccupied_back_zones()
			showZoneSelection(possibleZones)
			currentPrompt = 103
			
		121: #Attach Support
			var possibleZones = all_occupied_zones()
			showZoneSelection(possibleZones)
			currentPrompt = 121
		
		201: #Draw X
			set_prompt(tr("PROMPT_DRAW") + "\nX=")
			currentPrompt = 201
		203: #Mill X
			set_prompt(tr("PROMPT_DECK_ARCHIVE") + "\nX=",3)
			currentPrompt = 203
		250: #Shuffle Hand Into Deck
			can_undo_shuffle_hand = hand.duplicate()
		297: #Look at X
			set_prompt(tr("PROMPT_LOOKATX"),5)
			currentPrompt = 297
		298: #Search Deck
			showLookAt(deck.cardList)
			deck._update_looking(true)
			currentPrompt = 298
			currentFuda = deck
		
		397: #Look at X
			set_prompt(tr("PROMPT_LOOKATX"),3)
			currentPrompt = 397
		398: #Search Cheer Deck
			showLookAt(cheerDeck.cardList)
			cheerDeck._update_looking(true)
			currentPrompt = 398
			currentFuda = cheerDeck
		
		498: #Search Archive
			showLookAt(archive.cardList)
			currentPrompt = 498
			currentFuda = archive
		
		501: #Holopower X to Archive
			set_prompt(tr("PROMPT_HOLOPOWER_ARCHIVE") + "\nX=",3)
			currentPrompt = 501
		598: #Search Holopower
			showLookAt(holopower.cardList)
			holopower._update_looking(true)
			currentPrompt = 598
			currentFuda = holopower
		
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
		604: #Instant Bloom From Deck
			hideLookAt()
			var possibleZones = all_bloomable_zones(all_cards[currentCard])[Settings.bloomCode.Instant]
			showZoneSelection(possibleZones)
			currentPrompt = 604
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
		614: #Instant Bloom From Archive
			hideLookAt()
			var possibleZones = all_bloomable_zones(all_cards[currentCard])[Settings.bloomCode.Instant]
			showZoneSelection(possibleZones)
			currentPrompt = 614
		622: #Attach Cheer From Attach
			var possibleZones = all_occupied_zones(false,currentAttached.cardID)
			hideLookAt(false)
			showZoneSelection(possibleZones)
			currentPrompt = 622
		
		999: #Forfeit
			_show_loss_consent("FORFEIT")
			
	reset_popup()
	

func _on_line_edit_text_submitted(new_text):
	if new_text == "":
		new_text = prompt.get_node("Input/LineEdit").placeholder_text
	
	var input = new_text.to_int()
	if new_text.is_valid_int() and input > 0:
		send_command("Prompt Command", {"command_id":currentPrompt, "input":input, "currentCard":currentCard, "currentAttacking":currentAttacking})
	
		match currentPrompt:
			70:
				used_oshi_skill = true
				currentCard = -1
			71:
				used_sp_oshi_skill = true
				flipSPdown()
				currentCard = -1
			80,81: #Holomem Arts Damage
				var actualCard = all_cards[currentCard]
				var oppSide = get_parent().opponentSide
				var attacking = oppSide.all_cards[currentAttacking]
				var attackPos = attacking.position.rotated(-oppSide.rotation) + oppSide.position - get_parent().yourSide.position
				_move_sfx()
				actualCard.hitAndBack(attackPos)
	
	remove_prompt()

func _on_zone_clicked(zone_id):
	var actualZoneInfo = zones[zone_id]
	
	if is_your_side:
		send_command("Zone Command",{"command_id":currentPrompt, "currentCard":currentCard,"chosenZone":actualZoneInfo[0].name,"currentAttached":currentAttached.cardID if currentAttached else null})
		
	match currentPrompt:
		80,81: #Holomem Arts (called on opponent's side)
			var yourSide = get_parent().yourSide
			yourSide.currentAttacking = find_in_zone(actualZoneInfo[0])
			yourSide.set_prompt(tr("PROMPT_ART_DAMAGE"),20,3)
	
	currentAttached = null
	hideZoneSelection()

func _show_loss_consent(reason):
	if is_your_side:
		$CanvasLayer/Question/Label.text = tr("WINCONSENT_" + reason)
		losing_reason = "WINREASON_" + reason
		$CanvasLayer/Question/RPS.visible = false
		$CanvasLayer/Question/OK.visible = false
		$CanvasLayer/Question/Yes.visible = false
		$CanvasLayer/Question/No.visible = false
		
		$CanvasLayer/Question/Lose.visible = true
		$CanvasLayer/Question/KeepPlaying.visible = true
		$CanvasLayer/Question.visible = true

func _on_lose_pressed():
	get_parent().send_command("Game","Lose",{"reason": losing_reason})

func _on_keep_playing_pressed():
	losing_reason = ""
	$CanvasLayer/Question/Lose.visible = false
	$CanvasLayer/Question/KeepPlaying.visible = false
	$CanvasLayer/Question.visible = false

func _on_accept_damage(card_id):
	send_command("Accept Damage",{"card_id":card_id})

func _on_reject_damage(card_id):
	send_command("Reject Damage",{"card_id":card_id})

func _unhandled_key_input(event):
	if event.is_action_pressed("Draw") and is_your_side and can_do_things and deck.cardList.size() > 0:
		send_command("Popup Command",{"command_id":200})
	elif event.is_action_pressed("Cheer") and is_your_side and can_do_things and all_occupied_zones().size() > 0:
		send_command("Popup Command",{"command_id":300})
	elif event.is_action_pressed("Reset") and is_your_side and can_do_things:
		for zone in zones:
			if zone[1] in all_cards and all_cards[zone[1]].rested:
				send_command("Popup Command", {"currentCard":zone[1], "command_id":1})
		var collabed_id = find_in_zone(collabZone)
		if collabed_id != -1:
			send_command("Zone Command",{"command_id":5, "currentCard":collabed_id,"chosenZone":first_unoccupied_back_zone().name})
			send_command("Popup Command", {"currentCard":collabed_id, "command_id":0})

func _on_submit_pressed():
	_on_line_edit_text_submitted(prompt.get_node("Input/LineEdit").text)

func set_is_turn(value:bool):
	if is_your_side:
		is_turn = value
		get_parent()._select_step(1)
		if !preliminary_phase:
			$"CanvasLayer/End Turn".visible = value
			if deck.cardList.size() <= 0:
				_show_loss_consent("DECKOUT")

func set_player1(value:bool):
	if is_your_side:
		player1 = value
		if player1:
			$CanvasLayer/OpponentLabel/Label.text = tr("TURN_SECOND") #"Opponent Going Second"
			$CanvasLayer/OpponentLabel.visible = true
		else:
			$CanvasLayer/OpponentLabel/Label.text = tr("TURN_FIRST")
			$CanvasLayer/OpponentLabel.visible = true

func end_turn():
	if is_turn:
		step = 1
		first_turn = false
		used_limited = false
		collabed = false
		used_baton_pass = false
		used_oshi_skill = false
		can_undo_shuffle_hand = null
		for actualCard in all_cards.values():
			if actualCard.cardType == "Holomem":
				actualCard.bloomed_this_turn = false
		is_turn = false
		$"CanvasLayer/End Turn".visible = false
		emit_signal("ended_turn")
		get_parent()._enable_steps(true)


func _on_fuda_shuffled():
	_shuffle_sfx()

func _on_die_rolled():
	send_command("Roll Die")

func _shuffle_sfx():
	$Audio/Shuffling.play()

func _die_sfx():
	$Audio/Rolling.play()

func _draw_sfx():
	$Audio/Drawing.play()

func _place_sfx():
	$Audio/Placing.play()

func _move_sfx():
	$Audio/Moving.play()


func _is_card_onstage(card_to_check):
	var actual_card = all_cards[int(card_to_check)]
	return actual_card.onstage or int(card_to_check) in revealed or int(card_to_check) == playing


func send_command(command:String, data=null) -> void:
	get_parent().send_command("Side",command,data)

func side_command(command: String, data: Dictionary) -> void:
	match command:
		"Mulligan":
			if "forced" in data:
				_mulligan_decision(data["forced"])
		"No Mulligan":
			wait_mulligan()
		"Mulligan Done":
			if "forced_mulligan_cards" in data:
				specialStart3(data["forced_mulligan_cards"])
		"All Ready":
			if "life" in data and "is_turn" in data:
				specialStart4(data["life"],data["is_turn"])
		"Your Turn":
			set_is_turn(true)
			get_parent()._enable_steps(true)
			
		"Game Loss":
			game_loss()
		
		"Rest":
			if "card_id" in data:
				all_cards[int(data["card_id"])].rest()
		"Unrest":
			if "card_id" in data:
				all_cards[int(data["card_id"])].unrest()
		"Damage":
			if "card_id" in data and "amount" in data:
				all_cards[int(data["card_id"])].add_damage(int(data["amount"]))
		"Extra HP":
			if "card_id" in data and "amount" in data:
				all_cards[int(data["card_id"])].add_extra_hp(int(data["amount"]))
		"Offered Damage":
			if "card_id" in data and "amount" in data:
				all_cards[int(data["card_id"])].offer_damage(int(data["amount"]))
		"Accepted Damage":
			if "card_id" in data:
				all_cards[int(data["card_id"])]._on_reject_pressed()
		
		"Add To Hand":
			if "card_id" in data:
				add_to_hand(int(data["card_id"]))
		"Remove From Hand":
			if "card_id" in data:
				remove_from_hand(int(data["card_id"]))
		"Add To Fuda":
			if "card_id" in data and "to_fuda" in data and "bottom" in data:
				add_to_fuda(int(data["card_id"]),fuda_list[int(data["to_fuda"])],data["bottom"])
		"Remove From Fuda":
			if "card_id" in data and "from_fuda" in data:
				remove_from_fuda(int(data["card_id"]), fuda_list[int(data["from_fuda"])])
		"Remove From Attached":
			if "card_id" in data and "attached_id" in data:
				remove_from_attached(int(data["card_id"]),all_cards[int(data["attached_id"])])
		
		"Move Card To Zone":
			if "card_id" in data and "zone" in data:
				move_card_to_zone(int(data["card_id"]), $Zones.get_node(data["zone"]))
		"Switch Cards In Zones":
			if "zone_1" in data and "zone_2" in data:
				switch_cards_in_zones($Zones.get_node(data["zone_1"]), $Zones.get_node(data["zone_2"]))
		"Card Left Field":
			if "card_id" in data and _is_card_onstage(data["card_id"]):
				remove_old_card(int(data["card_id"]),true)
		"Attach Card":
			if "attachee" in data and "attach_to" in data:
				attach_card(int(data["attachee"]), int(data["attach_to"]))
		"Bloom":
			if "card_to_bloom" in data and "zone_to_bloom" in data:
				bloom_on_zone(all_cards[int(data["card_to_bloom"])], $Zones.get_node(data["zone_to_bloom"]))
		"Unbloom":
			if "card_to_unbloom" in data:
				unbloom_on_zone(int(data["card_to_unbloom"]))
		"Collab":
			collabed = true
		"Baton Pass":
			used_baton_pass = true
		"Card Played":
			if "card_id" in data:
				all_cards[int(data["card_id"])].bloomed_this_turn = true
		
		"Reveal":
			if "card_id" in data:
				reveal_card(int(data["card_id"]))
		"Reveal Cheer":
			if "card_id" in data:
				reveal_cheer(int(data["card_id"]))
		"Reveal Life":
			if "card_id" in data:
				life[0].flipUp()
				life.pop_front()
		"Play Support":
			if "card_id" in data:
				play_card(int(data["card_id"]))
		"To Life":
			if "card_id" in data:
				add_to_life(int(data["card_id"]))
		
		"Look At X":
			if "fuda" in data and "ids" in data:
				showLookAtIDS(data["ids"])
				currentFuda = fuda_list[int(data["fuda"])]
				currentFuda._update_looking(true,data["ids"].size())
				currentPrompt = 297 if currentFuda == deck else 397
				
		"Remove From List":
			if "card_id" in data:
				removeFromLookAt(int(data["card_id"]))
		
		"Shuffle Fuda":
			if "fuda" in data:
				fuda_list[int(data["fuda"])].shuffle()
		"Roll Die":
			if "result" in data:
				#emit_signal("sent_game_message",tr("MESSAGE_DIERESULT").format({amount = num}))
				die.roll(int(data["result"]))
				_die_sfx()
		"Click Notification":
			if "card_id" in data:
				all_cards[int(data["card_id"])].showNotice()
		
		_:
			pass

func opponent_side_command(command: String, data: Dictionary) -> void:
	match command:
		"Rest":
			if "card_id" in data:
				all_cards[int(data["card_id"])].rest()
		"Unrest":
			if "card_id" in data:
				all_cards[int(data["card_id"])].unrest()
		"Damage":
			if "card_id" in data and int(data["card_id"]) in all_cards and "amount" in data:
				all_cards[int(data["card_id"])].add_damage(int(data["amount"]))
		"Extra HP":
			if "card_id" in data and int(data["card_id"]) in all_cards and "amount" in data:
				all_cards[int(data["card_id"])].add_extra_hp(int(data["amount"]))
		
		"Add To Hand":
			add_fake_to_hand()
		"Remove From Hand":
			remove_fake_from_hand()
		"Add To Fuda":
			if "to_fuda" in data and "moved_card" in data:
				add_fake_to_fuda(fuda_list[int(data["to_fuda"])],data["moved_card"])
		"Remove From Fuda":
			if "from_fuda" in data:
				remove_fake_from_fuda(fuda_list[int(data["from_fuda"])], data["removed_card"] if "removed_card" in data else null)
		"Remove From Attached":
			if "card_id" in data and "attached_id" in data:
				remove_fake_from_attached(int(data["card_id"]),int(data["attached_id"]))
		"All Ready":
			if "oshi" in data and "zones" in data:
				specialStart4_fake(data["oshi"],data["zones"])
		
		
		"Card Left Field":
			if "card_id" in data and int(data["card_id"]) in all_cards and _is_card_onstage(data["card_id"]):
				remove_old_card(int(data["card_id"]),true)
		"Move Card To Zone":
			if "card" in data and "zone" in data and "facedown" in data:
				move_fake_card_to_zone(data["card"], $Zones.get_node(data["zone"]), data["facedown"])
		"Switch Cards In Zones":
			if "zone_1" in data and "zone_2" in data:
				switch_cards_in_zones($Zones.get_node(data["zone_1"]), $Zones.get_node(data["zone_2"]))
		"Bloom":
			if "card" in data and "zone_to_bloom" in data:
				bloom_fake_on_zone(data["card"], $Zones.get_node(data["zone_to_bloom"]))
		"Unbloom":
			if "card_to_unbloom" in data:
				unbloom_fake_on_zone(int(data["card_to_unbloom"]))
		"Attach Card":
			if "attachee_info" in data and "attach_to_info" in data:
				attach_fake_card(data["attachee_info"], data["attach_to_info"])
		
		"Reveal":
			if "card" in data:
				reveal_fake_card(data["card"])
		"Reveal Cheer":
			if "card" in data:
				reveal_fake_cheer(data["card"])
		"Reveal Life":
			if "card" in data:
				reveal_fake_life(data["card"])
		"Play Support":
			if "card" in data:
				play_fake_card(data["card"])
		"To Life":
			add_fake_to_life()
		
		"Look At X":
			if "fuda" in data and "X" in data:
				var actualFuda = fuda_list[int(data["fuda"])]
				actualFuda._update_looking(true,int(data["X"]))
				fuda_opponent_looking_at = actualFuda
		"Look At":
			if "fuda" in data:
				var actualFuda = fuda_list[int(data["fuda"])]
				actualFuda._update_looking(true)
				fuda_opponent_looking_at = actualFuda
		"Stop Look At":
			if fuda_opponent_looking_at:
				fuda_opponent_looking_at._update_looking(false)
				fuda_opponent_looking_at = null
		"Used SP Skill":
			flipSPdown()
		
		"Shuffle Fuda":
			if "fuda" in data:
				fuda_list[int(data["fuda"])].shuffle()
		"Roll Die":
			if "result" in data:
				#emit_signal("sent_game_message",tr("MESSAGE_DIERESULT").format({amount = num}))
				die.roll(int(data["result"]))
				_die_sfx()
		"Attack":
			if "attacker" in data and "attacked" in data:
				var attacker = all_cards[int(data["attacker"])]
				var yourSide = get_parent().yourSide
				if !yourSide:
					#For spectator
					for side in get_parent().spectatedSides:
						if side != player_id:
							yourSide = get_parent().spectatedSides[side]
				var attacked = yourSide.all_cards[int(data["attacked"])]
				var attackPos = attacked.position.rotated(-rotation) + position - yourSide.position
				if !is_your_side and is_front:
					#For spectator if the player attacking is on their side
					attackPos = attacked.position.rotated(-yourSide.rotation) + yourSide.position - position
				_move_sfx()
				attacker.hitAndBack(attackPos)
		"Click Notification":
			if "card_id" in data and int(data["card_id"]) in all_cards:
				all_cards[int(data["card_id"])].showNotice()
		_:
			pass
