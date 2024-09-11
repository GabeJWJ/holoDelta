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

@onready var deck = $SubViewportContainer/SubViewport/Node3D/Deck
@onready var cheerDeck = $SubViewportContainer/SubViewport/Node3D/CheerDeck
@onready var archive = $SubViewportContainer/SubViewport/Node3D/Archive
@onready var holopower = $SubViewportContainer/SubViewport/Node3D/Holopower
@onready var die = $SubViewportContainer/SubViewport/Node3D/Die
@onready var spMarker = $SPmarker

var currentCard = -1
var currentFuda = null
var currentAttached = null
var currentPrompt = -1
var playing = null
var revealed = []

@onready var zones = [[centerZone,-1], [collabZone,-1], [backZone1,-1], [backZone2,-1], [backZone3,-1], [backZone4,-1], [backZone5,-1]]

const card = preload("res://Scenes/card.tscn")
const betterButton = preload("res://Scenes/better_texture_button.tscn")

var all_cards = []
var oshiCard
var hand = []
var life = []

@export var oshi:Array
@export var deckList:Array
@export var cheerDeckList:Array

var database : SQLite

@export var preliminary_phase = true
var penalty = 0
var preliminary_holomem_in_center = false
@export var is_turn = false
var first_turn = true
var player1 = false
var used_limited = false
var used_baton_pass = false
var collabed = false
var used_oshi_skill = false
var used_sp_oshi_skill = false
signal ended_turn
signal made_turn_choice(choice)
signal rps(choice)
signal ready_decided

signal card_info_set(card_num, desc, art_data)
signal card_info_clear

signal entered_list
signal exited_list


func _enter_tree():
	set_multiplayer_authority(name.to_int())

# Called when the node enters the scene tree for the first time.
func _ready():
	if name != "1":
		position = Vector2(0,-1044)
		rotation = -3.141
		$SubViewportContainer/SubViewport/Node3D.position += Vector3(1000,0,1000)
	
	$SubViewportContainer.set_multiplayer_authority(name.to_int())
	
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
	
	database = SQLite.new()
	database.read_only = true
	if OS.has_feature("editor"):
		database.path = "res://cardData.db"
	else:
		database.path = OS.get_executable_path().get_base_dir() + "/cardData.db"
	database.open_db()
	
	oshiCard = create_card(oshi[0],oshi[1])
	oshiCard.position = Vector2(430,-253)
	oshiCard.visible = false
	oshiCard.z_index = 1
	
	for info in cheerDeckList:
		for i in range(info[1]):
			var newCard1 = create_card(info[0],info[2])
			cheerDeck.cardList.append(newCard1)
			newCard1.visible = false
	
	for info in deckList:
		for i in range(info[1]):
			var newCard1 = create_card(info[0],info[2])
			deck.cardList.append(newCard1)
			newCard1.visible = false
			newCard1.z_index = 1
	
	deck.cardList.shuffle()
	cheerDeck.cardList.shuffle()
	
	deck.update_size()
	cheerDeck.update_size()
	archive.update_size()
	holopower.update_size()
	
	database.close_db()
	
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
	$CanvasLayer/Question.visible = true

func _rps(choice):
	$CanvasLayer/Question/Label.text = "Waiting for opponent..."
	$CanvasLayer/Question/Rock.disabled = true
	$CanvasLayer/Question/Paper.disabled = true
	$CanvasLayer/Question/Scissors.disabled = true
	emit_signal("rps",choice)

func _restart():
	specialRestart.rpc()

@rpc("any_peer","call_remote","reliable")
func specialRestart():
	$CanvasLayer/Question/Label.text = "Tied. Pick again."
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

func _start2():
	specialStart2.rpc()

@rpc("any_peer","call_remote","reliable")
func specialStart2():
	draw(7)
	
	$CanvasLayer/Question/Label.text = "Mulligan?"
	$CanvasLayer/Question/Yes.visible = true
	$CanvasLayer/Question/No.visible = true
	$CanvasLayer/Question.visible = true
	
	if !hasLegalHand():
		$CanvasLayer/Question/No.disabled = true
	else:
		$CanvasLayer/Question/No.disabled = false

func yes_mulligan():
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
		$CanvasLayer/Question/Label.text = "You lose."
		$CanvasLayer/Question/OK.visible = false
	else:
		$CanvasLayer/Question/Label.text = "No Debut holomems.\nYou must mulligan."
		$CanvasLayer/Question/Yes.visible = false
		$CanvasLayer/Question/No.visible = false
		$CanvasLayer/Question/OK.visible = true
		penalty += 1

func no_mulligan():
	$CanvasLayer/Question.visible = false
	$CanvasLayer/Ready.visible = true

func _call_ready():
	emit_signal("ready_decided")
	$CanvasLayer/Ready.disabled = true
	$CanvasLayer/Ready.text = "Waiting"

func _start3():
	specialStart3.rpc()

@rpc("any_peer","call_remote","reliable")
func specialStart3():
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
		newLife.position = Vector2(-860,-155-(53*(6-oshiCard.life+i)))
		newLife.rest()
		newLife.visible = true
	
	cheerDeck.update_size()

func hasLegalHand():
	for actualCard in hand:
		if actualCard.cardType == "Holomem" and actualCard.level == 0:
			return true
	return false



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func create_card(number,art_code):
	var new_id = all_cards.size()
	var newCard = card.instantiate()
	add_child(newCard,true)
	newCard.name = "Card" + str(new_id)
	newCard.setup_info(number,database,art_code)
	newCard.cardID = new_id
	newCard.card_clicked.connect(_on_card_clicked)
	newCard.card_mouse_over.connect(update_info)
	#newCard.card_mouse_left.connect(clear_info)
	newCard.move_behind_request.connect(_on_move_behind_request)
	all_cards.append(newCard)
	newCard.set_multiplayer_authority(name.to_int())
	newCard.position = Vector2(1000,1000)
	return newCard

func update_hand():
	var max_offset = 125 * (hand.size() - 1)
	for i in range(hand.size()):
		hand[i].flipDown.rpc()
		hand[i].position = Vector2(-max_offset,750) + (i * Vector2(250,0))
		hand[i].visible = true

func draw(x=1):
	for i in range(x):
		add_to_hand(deck.cardList.pop_front().cardID)
	deck.update_size()

func mill(fromFuda,toFuda,x=1):
	for i in range(x):
		add_to_fuda(fromFuda.cardList.pop_front().cardID,toFuda)
	fromFuda.update_size()

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
		actualCard.unrest()
		actualCard.attached = []
		actualCard.onTopOf = []
	for index in range(zones.size()):
		if zones[index][1] == old_card:
			zones[index][1] = -1

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
		attached.update_attached()
	elif all_cards[card_id] in attached.onTopOf:
		remove_from_card_list(card_id,attached.onTopOf)

func add_to_card_list(card_id,list_of_cards,bottom=false):
	var new_position = 0
	if bottom:
		new_position = list_of_cards.size()
	var cardToGo = all_cards[card_id]
	
	cardToGo.attached.reverse()
	cardToGo.onTopOf.reverse()
	for newCard in cardToGo.attached:
		add_to_card_list(newCard.cardID,list_of_cards,bottom)
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
	
	if find_what_zone(card_id):
		remove_old_card(card_id)
	
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
	
	set_zone_card(zone_1,card2.cardID)
	set_zone_card(zone_2,card1.cardID)

func bloom_on_zone(card_to_bloom, zone_to_bloom):
	var bloomee =all_cards[find_in_zone(zone_to_bloom)]
	card_to_bloom.bloom(bloomee)
	set_zone_card(zone_to_bloom,card_to_bloom.cardID)
	remove_from_hand(card_to_bloom.cardID)


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
	cancel.visible = false

func showLookAt(list_of_cards):
	for i in range(list_of_cards.size()):
		var actualCard = list_of_cards[i]
		var newButton = betterButton.instantiate()
		newButton.set_texture(actualCard.cardFront)
		newButton.id = actualCard.cardID
		newButton.pressed.connect(_on_list_card_clicked.bind(actualCard.cardID))
		newButton.mouse_entered.connect(update_info.bind(actualCard.cardID))
		newButton.mouse_exited.connect(clear_info)
		lookAtList.add_child(newButton)
		newButton.scale = Vector2(0.7,0.7)
		newButton.position = Vector2(280*i+5,5)
	
	lookAtList.custom_minimum_size = Vector2(list_of_cards.size()*280 + 10, 0)
	lookAt.get_h_scroll_bar().custom_minimum_size.y = 30
	
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

@rpc("any_peer","call_remote","reliable")
func wannaLookAtArchive():
	var json = JSON.new()
	var list_of_ids = []
	for actualCard in archive.cardList:
		list_of_ids.append(actualCard.cardID)
	showLookAtIDS.rpc(json.stringify(list_of_ids))

@rpc("any_peer","call_remote","reliable")
func wannaLookAtAttached(attach_id):
	var json = JSON.new()
	var list_of_ids = []
	for actualCard in all_cards[attach_id].attached:
		list_of_ids.append(actualCard.cardID)
	showLookAtIDS.rpc(json.stringify(list_of_ids))

@rpc("any_peer","call_remote","reliable")
func popupForAttached():
	popup.clear()
	
	if currentPrompt != -1:
		return
	popup.add_item(Settings.en_or_jp("Look at attached","添付を見る"),51)
		
	if popup.item_count > 0:
		popup.visible = true
		popup.position = get_viewport().get_mouse_position()

@rpc("any_peer","call_remote","reliable")
func wannaPopupForAttached(attach_id):
	if find_what_zone(attach_id) and all_cards[attach_id].attached.size() > 0:
		popupForAttached.rpc()

@rpc("any_peer","call_remote","reliable")
func popupForArchive():
	popup.clear()
	
	if currentPrompt != -1:
		return
	
	popup.add_item(Settings.en_or_jp("Search","一覧を見る"),497)
		
	if popup.item_count > 0:
		popup.visible = true
		popup.position = get_viewport().get_mouse_position()

func removeFromLookAt(card_id):
	var remaining = lookAtList.get_children().size() - 1
	var i = 0
	for newButton in lookAtList.get_children():
		if newButton.id == card_id:
			newButton.queue_free()
		else:
			newButton.position = Vector2(280*i+5,5)
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
	hideLookAt()
	remove_prompt()
	hideZoneSelection()


func _on_zone_enter(zone_id):
	var card_id = zones[zone_id][1]
	if card_id != -1:
		update_info(card_id)

func _on_archive_mouse_entered():
	if archive.cardList.size() > 0:
		update_info(archive.cardList[0].cardID)
	elif !is_multiplayer_authority():
		archive_opponent_mouse_enter.rpc()

@rpc("any_peer","call_remote","reliable")
func archive_opponent_mouse_enter():
	if archive.cardList.size() > 0:
		update_info.rpc(archive.cardList[0].cardID)

@rpc("any_peer","call_remote","reliable")
func update_info(card_id):
	var actualCard = all_cards[card_id]
	if !actualCard.trulyHidden and (is_multiplayer_authority() or !actualCard.faceDown):
		emit_signal("card_info_set",actualCard.cardNumber,actualCard.full_desc(),actualCard.cardFront)

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
	if currentPrompt != -1:
		return
	
	if !is_multiplayer_authority():
		currentCard = card_id
		wannaPopupForAttached.rpc(card_id)
		return
	
	popup.clear()
	currentCard = card_id
	
	var actualCard = all_cards[currentCard]
	
	if preliminary_phase:
		if actualCard.cardType == "Holomem" and actualCard in hand and actualCard.level < 1:
			if !preliminary_holomem_in_center and actualCard.level == 0:
				popup.add_item("Play (hidden) to center", 102)
			if preliminary_holomem_in_center or actualCard.level == -1:
				popup.add_item("Play (hidden) to back", 103)
	else:
		match actualCard.cardType:
			"Holomem":
				if is_multiplayer_authority():
					if actualCard in hand and is_turn:
						if first_unoccupied_back_zone() and actualCard.level < 1 and all_occupied_zones().size() < 6:
							popup.add_item(Settings.en_or_jp("Play","場に出す"),100)
						if !first_turn:
							var bloomable = all_bloomable_zones(actualCard)
							if bloomable[Settings.bloomCode.OK].size() > 0:
								popup.add_item("Bloom",101)
							if bloomable[Settings.bloomCode.Skip].size() > 0:
								popup.add_item("Skip Bloom",104)
							if bloomable[Settings.bloomCode.Instant].size() > 0:
								popup.add_item("Instant Bloom",105)
					elif find_what_zone(currentCard):
						if is_turn:
							if actualCard.rested:
								popup.add_item(Settings.en_or_jp("Unrest","縦向きにさせたる"), 1)
							else:
								popup.add_item(Settings.en_or_jp("Rest","お休みさせたる"), 0)
							
							var currentZone = find_what_zone(currentCard)
							if currentZone:
								if find_in_zone(centerZone) == -1 and currentZone != collabZone:
									popup.add_item("Move to Center", 4)
								if currentZone == collabZone and first_unoccupied_back_zone():
									popup.add_item("Move to Back", 5)
								if find_in_zone(collabZone) == -1 and currentZone != centerZone and !actualCard.rested and !collabed:
									popup.add_item(Settings.en_or_jp("Collab","コラボする"), 6)
								if currentZone == centerZone and all_occupied_zones(true).size() > 0 and !used_baton_pass:
									popup.add_item(Settings.en_or_jp("Baton Pass","バトンタッチする"), 7)
							
							popup.add_separator()
						
						popup.add_item("Add Damage", 10)
						if actualCard.damage > 0:
							popup.add_item("Remove Damage", 11)
						popup.add_item("Add Extra HP", 12)
						if actualCard.extra_hp > 0:
							popup.add_item("Remove Extra HP", 13)
						
						if actualCard.onTopOf.size() > 0:
							popup.add_separator()
							popup.add_item("Unbloom", 15)
			"Support":
				if actualCard in hand:
					if is_turn:
						if actualCard.supportType in ["Tool","Mascot","Fan"]:
							if all_occupied_zones().size() > 0:
								popup.add_item("Attach", 121)
						else:
							var cantUseLimited = used_limited or (first_turn and player1)
							if playing == null and !(actualCard.limited and cantUseLimited):
								popup.add_item(Settings.en_or_jp("Play","使う"),120)
				elif playing == currentCard:
					popup.add_item(Settings.en_or_jp("Archive","アーカイブする"),20)
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
					if canUseSkill and canPayCost:
						popup.add_item(Settings.en_or_jp("\"","「") + skill[0] + Settings.en_or_jp("\"","」") + sp_string + "-" + cost_string,70+i) #Will cause problems if an oshi has more than 2 skills
		
		if popup.item_count > 0 and actualCard.cardType != "Oshi":
			popup.add_separator()
		
		if life.size() > 0 and actualCard == life[0] and all_occupied_zones().size() > 0:
			popup.add_item("Reveal and attach", 30)
		
		if find_what_zone(currentCard):
			var serf = false
			if actualCard.attached.size() > 0:
				popup.add_item(Settings.en_or_jp("Look at attached","添付を見る"),50)
				serf = true
			if actualCard.onTopOf.size() > 0:
				popup.add_item("Look at past blooms",52)
				serf = true
			if serf:
				popup.add_separator()
		
		if actualCard.cardType != "Oshi":
			if actualCard in hand:
				popup.add_item("Put on top of Deck",110)
				popup.add_item("Put on bottom of Deck",111)
				popup.add_item(Settings.en_or_jp("Archive","アーカイブする"),112)
				popup.add_item("Holopower",113)
			elif find_what_zone(currentCard):
				popup.add_item(Settings.en_or_jp("Archive","アーカイブする"),2)
				if actualCard.attached.size() == 0:
					popup.add_item("Return to Hand",3)
				if find_what_zone(currentCard) == centerZone and all_occupied_zones(true).size() > 0 :
					popup.add_item("Switch to Back", 8)
			elif currentCard in revealed:
				popup.add_item("Add to Hand",21)
				if actualCard.cardType == "Support" and actualCard.supportType in ["Tool","Mascot","Fan"] and all_occupied_zones().size() > 0:
					popup.add_item("Attach",22)
	
	if popup.item_count > 0:
		popup.visible = true
		popup.position = get_viewport().get_mouse_position()

func _on_deck_clicked():
	popup.clear()
	
	if preliminary_phase or currentPrompt != -1:
		return
	
	if is_multiplayer_authority():
		
		popup.add_item(Settings.en_or_jp("Draw","引く"),200)
		popup.add_item(Settings.en_or_jp("Draw X","X枚引く"),201)
		popup.add_item("Mill",202)
		popup.add_item("Mill X",203)
		popup.add_item("Holopower",204)
		
		popup.add_separator()
		
		popup.add_item("Shuffle hand into Deck", 250)
		
		popup.add_separator()
		popup.add_item("Look at X",297)
		popup.add_item(Settings.en_or_jp("Search","一覧を見る"),298)
		popup.add_item("Shuffle",299)
		
	if popup.item_count > 0:
		popup.visible = true
		popup.position = get_viewport().get_mouse_position()

func _on_cheer_deck_clicked():
	popup.clear()
	
	if preliminary_phase or currentPrompt != -1:
		return
	
	if is_multiplayer_authority():
		if all_occupied_zones().size() > 0:
			popup.add_item("Reveal & Attach",300)
		
		if popup.item_count > 0:
			popup.add_separator()
		
		popup.add_item(Settings.en_or_jp("Search","一覧を見る"),398)
		popup.add_item("Shuffle",399)
		
	if popup.item_count > 0:
		popup.visible = true
		popup.position = get_viewport().get_mouse_position()

func _on_archive_clicked():
	if preliminary_phase or currentPrompt != -1:
		return
	
	if !is_multiplayer_authority():
		popupForArchive()
		return
	
	popup.clear()
	
	
	popup.add_item(Settings.en_or_jp("Search","一覧を見る"),498)
		
	if popup.item_count > 0:
		popup.visible = true
		popup.position = get_viewport().get_mouse_position()

func _on_holopower_clicked():
	popup.clear()
	
	if preliminary_phase or currentPrompt != -1:
		return
	
	if is_multiplayer_authority():
		popup.add_item("To Archive",500)
		popup.add_item("X To Archive",501)
		
		popup.add_separator()
		
		popup.add_item(Settings.en_or_jp("Search","一覧を見る"),598)
		popup.add_item("Shuffle",599)
		
	if popup.item_count > 0:
		popup.visible = true
		popup.position = get_viewport().get_mouse_position()

func _on_list_card_clicked(card_id):
	if preliminary_phase or currentPrompt == -1 or !is_multiplayer_authority():
		return
	
	popup.clear()
	currentCard = card_id
	
	var actualCard = all_cards[currentCard]
	var fullFuda = true
	if currentPrompt in [297]:
		fullFuda = false
	
	#Requires zone target and thus must be broken up by fuda
	match actualCard.cardType:
		"Holomem":
			if first_unoccupied_back_zone() and actualCard.level < 1 and is_turn:
				if currentFuda == deck:
					popup.add_item(Settings.en_or_jp("Play","場に出す"),600)
				elif currentFuda == archive:
					popup.add_item(Settings.en_or_jp("Play","場に出す"),610)
			if all_bloomable_zones(actualCard)[Settings.bloomCode.OK].size() > 0 and is_turn and !first_turn:
				if currentFuda == deck:
					popup.add_item("Bloom",601)
				elif currentFuda == archive:
					popup.add_item("Bloom",611)
		"Cheer":
			if all_occupied_zones().size() > 0:
				if currentFuda == cheerDeck:
					popup.add_item("Attach",602)
				elif currentFuda == archive:
					popup.add_item("Attach",612)
				elif currentAttached != null and all_occupied_zones().size() > 1:
					popup.add_item("Reattach",622)
	
	if currentFuda in [deck,archive,holopower] and actualCard.cardType != "Cheer":
		popup.add_item("Reveal", 630)
	
	if popup.item_count > 0:
		popup.add_separator()
	
	#Done automatically and thus does not need to be broken up by fuda.
	if actualCard.cardType != "Cheer":
		popup.add_item("Add to Hand", 650)
	
	if (!fullFuda or currentFuda != deck) and actualCard.cardType != "Cheer":
		popup.add_item("Put on top of Deck",651)
		popup.add_item("Put on bottom of Deck",652)
	if (!fullFuda or currentFuda != cheerDeck) and actualCard.cardType == "Cheer":
		popup.add_item("Put on top of Cheer Deck",653)
		popup.add_item("Put on bottom of Cheer Deck",654)
	if currentFuda != archive:
		popup.add_item(Settings.en_or_jp("Archive","アーカイブする"),655)
	if currentFuda != holopower and actualCard.cardType != "Cheer":
		popup.add_item("Holopower",656)
	
	if popup.item_count > 0:
		popup.visible = true
		popup.position = get_viewport().get_mouse_position()


func _on_popup_menu_id_pressed(id):
	match id:
		0: #Rest
			all_cards[currentCard].rest()
			currentCard = -1
		1: #Unrest
			all_cards[currentCard].unrest()
			currentCard = -1
		2: #Archive
			all_cards[currentCard].clear_damage()
			all_cards[currentCard].clear_extra_hp()
			add_to_fuda(currentCard,archive)
			remove_old_card(currentCard,true)
			if playing == currentCard:
				playing = null
			currentCard = -1
		3: #Return to Hand
			var actualCard = all_cards[currentCard]
			actualCard.clear_damage()
			actualCard.clear_extra_hp()
			actualCard.unrest()
			add_to_hand(currentCard)
			remove_old_card(currentCard,true)
			currentCard = -1
		4: #Move to Center
			move_card_to_zone(currentCard,centerZone)
			currentCard = -1
		5: #Move to Back
			showZoneSelection(all_unoccupied_back_zones())
			currentPrompt = 5
		6: #Collab
			move_card_to_zone(currentCard,collabZone)
			if deck.cardList.size() > 0:
				mill(deck,holopower)
			collabed = true
			currentCard = -1
		7: #Baton Pass
			showZoneSelection(all_occupied_zones(true))
			currentPrompt = 7
		8: #Switch to Back
			showZoneSelection(all_occupied_zones(true))
			currentPrompt = 8
		10: #Add Damage
			set_prompt("Add X Damage\nX=",20,3)
			currentPrompt = 10
		11: #Remove Damage
			set_prompt("Heal X Damage\nX=",20,3)
			currentPrompt = 11
		12: #Add Extra HP
			set_prompt("Add X HP\nX=",10,2)
			currentPrompt = 12
		13: #Remove Extra HP
			set_prompt("Remove X HP\nX=",10,2)
			currentPrompt = 13
		15: #Unbloom
			var actualCard = all_cards[currentCard]
			var newCard = actualCard.onTopOf[0].cardID
			actualCard.unbloom()
			for index in range(zones.size()):
				if zones[index][1] == currentCard:
					zones[index][1] = newCard
			add_to_hand(currentCard)
			currentCard = -1
		20: #Archive Support in Play
			add_to_fuda(currentCard,archive)
			if playing == currentCard:
				all_cards[currentCard].z_index = 1
			playing = null
			currentCard = -1
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
		51: #Look At Opponent's Attached
			currentAttached = all_cards[currentCard]
			wannaLookAtAttached.rpc(currentCard)
			currentPrompt = 51
		52: #Look At Past Blooms
			currentAttached = all_cards[currentCard]
			showLookAt(currentAttached.onTopOf)
			currentPrompt = 52
		70:
			var skill = all_cards[currentCard].oshi_skills[0]
			if skill[1] >= 0:
				mill(holopower,archive,skill[1])
				if skill[2]:
					used_sp_oshi_skill = true
					flipSPdown.rpc()
				else:
					used_oshi_skill = true
				currentCard = -1
			else:
				set_prompt("Archive X\nX=",3)
				currentPrompt = 70
		71:
			var skill = all_cards[currentCard].oshi_skills[1]
			if skill[1] >= 0:
				mill(holopower,archive,skill[1])
				if skill[2]:
					used_sp_oshi_skill = true
					flipSPdown.rpc()
				else:
					used_oshi_skill = true
				currentCard = -1
			else:
				set_prompt("Archive X\nX=",3)
				currentPrompt = 71
		
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
			hideZoneSelection()
			preliminary_holomem_in_center = true
			$CanvasLayer/Ready.disabled = false
		103: #Play Hidden to Back
			var possibleZones = all_unoccupied_back_zones()
			showZoneSelection(possibleZones)
			currentPrompt = 103
		110: #Return to top of deck
			add_to_fuda(currentCard,deck)
			remove_from_hand(currentCard)
			currentCard = -1
		111: #Return to bottom of deck
			add_to_fuda(currentCard,deck,-1)
			remove_from_hand(currentCard)
			currentCard = -1
		112: #Archive
			add_to_fuda(currentCard,archive)
			remove_from_hand(currentCard)
			currentCard = -1
		113: #Archive
			add_to_fuda(currentCard,holopower)
			remove_from_hand(currentCard)
			currentCard = -1
		120: #Play Support
			var actualCard = all_cards[currentCard]
			if actualCard.limited:
				used_limited = true
			actualCard.z_index = 2
			remove_from_hand(currentCard)
			actualCard.position = Vector2(0,0)
			playing = currentCard
			currentCard = -1
			
		121: #Attach Support
			var possibleZones = all_occupied_zones()
			showZoneSelection(possibleZones)
			currentPrompt = 121
		
		200: #Draw
			draw()
		201: #Draw X
			set_prompt("Draw X cards\nX=")
			currentPrompt = 201
		202: #Mill
			mill(deck,archive)
		203: #Mill X
			set_prompt("Mill X cards\nX=",3)
			currentPrompt = 203
		204: #Holopower
			mill(deck,holopower)
		250: #Shuffle Hand Into Deck
			var list_of_ids = []
			for hand_card in hand:
				list_of_ids.append(hand_card.cardID)
			for hand_id in list_of_ids:
				add_to_fuda(hand_id,deck)
				remove_from_hand(hand_id)
			deck.shuffle()
		297: #Look at X
			set_prompt("Look at top X\nX=",5)
			currentPrompt = 297
		298: #Search Deck
			showLookAt(deck.cardList)
			deck._update_looking(true)
			currentPrompt = 298
			currentFuda = deck
		299: #Shuffle
			deck.shuffle()
		
		300: #Reveal and Attach Cheer
			var possibleZones = all_occupied_zones()
			var cheerCard = cheerDeck.cardList.pop_front()
			cheerCard.visible = true
			cheerCard.z_index = 2
			cheerCard.position = Vector2(-900,-50)
			currentCard = cheerCard.cardID
			cheerDeck.update_size()
			showZoneSelection(possibleZones,false)
			currentPrompt = 300
		398: #Search Cheer Deck
			showLookAt(cheerDeck.cardList)
			cheerDeck._update_looking(true)
			currentPrompt = 398
			currentFuda = cheerDeck
		399: #Shuffle
			cheerDeck.shuffle()
		
		497: #Search Opponent's Archive
			wannaLookAtArchive.rpc()
			currentPrompt = 497
		498: #Search Archive
			if is_multiplayer_authority():
				showLookAt(archive.cardList)
			else:
				wannaLookAtArchive.rpc()
			currentPrompt = 498
			currentFuda = archive
		
		500: #Holopower to Archive
			mill(holopower,archive)
		501: #Holopower X to Archive
			set_prompt("Archive X\nX=",3)
			currentPrompt = 501
		598: #Search Holopower
			showLookAt(holopower.cardList)
			holopower._update_looking(true)
			currentPrompt = 598
			currentFuda = holopower
		599: #Shuffle
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
			var possibleZones = all_bloomable_zones(all_cards[currentCard])
			showZoneSelection(possibleZones)
			currentPrompt = 601
		602: #Attach Cheer From Deck
			hideLookAt()
			var possibleZones = all_occupied_zones()
			showZoneSelection(possibleZones)
			currentPrompt = 602
		610: #Play From Archive
			hideLookAt()
			var possibleZones = all_unoccupied_back_zones()
			if zones[0][1] == -1:
				possibleZones.append(centerZone)
			showZoneSelection(possibleZones)
			currentPrompt = 610
		611: #Bloom From Archive
			hideLookAt()
			var possibleZones = all_bloomable_zones(all_cards[currentCard])
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
			actualCard.z_index = 2
			remove_from_fuda(currentCard,currentFuda)
			removeFromLookAt(currentCard)
			actualCard.position = Vector2(300,100*revealed.size())
			if revealed.size() > 0:
				move_behind.rpc(revealed[-1],currentCard)
			revealed.append(currentCard)
			currentCard = -1
		650: #Add to Hand
			if currentFuda:
				remove_from_fuda(currentCard,currentFuda)
			elif currentAttached:
				remove_from_attached(currentCard,currentAttached)
			all_cards[currentCard].unrest()
			add_to_hand(currentCard)
			removeFromLookAt(currentCard)
			currentCard = -1
		651: #Return to top of deck
			if currentFuda:
				remove_from_fuda(currentCard,currentFuda)
			elif currentAttached:
				remove_from_attached(currentCard,currentAttached)
			all_cards[currentCard].unrest()
			add_to_fuda(currentCard,deck)
			removeFromLookAt(currentCard)
			currentCard = -1
		652: #Return to bottom of deck
			if currentFuda:
				remove_from_fuda(currentCard,currentFuda)
			elif currentAttached:
				remove_from_attached(currentCard,currentAttached)
			all_cards[currentCard].unrest()
			add_to_fuda(currentCard,deck,-1)
			removeFromLookAt(currentCard)
			currentCard = -1
		653: #Return to top of cheer deck
			if currentFuda:
				remove_from_fuda(currentCard,currentFuda)
			elif currentAttached:
				remove_from_attached(currentCard,currentAttached)
			all_cards[currentCard].unrest()
			add_to_fuda(currentCard,cheerDeck)
			removeFromLookAt(currentCard)
			currentCard = -1
		654: #Return to bottom of cheer deck
			if currentFuda:
				remove_from_fuda(currentCard,currentFuda)
			elif currentAttached:
				remove_from_attached(currentCard,currentAttached)
			all_cards[currentCard].unrest()
			add_to_fuda(currentCard,cheerDeck,-1)
			removeFromLookAt(currentCard)
			currentCard = -1
		655: #Archive
			if currentFuda:
				remove_from_fuda(currentCard,currentFuda)
			elif currentAttached:
				remove_from_attached(currentCard,currentAttached)
			all_cards[currentCard].unrest()
			add_to_fuda(currentCard,archive)
			removeFromLookAt(currentCard)
			currentCard = -1
		656: #Holopower
			if currentFuda:
				remove_from_fuda(currentCard,currentFuda)
			elif currentAttached:
				remove_from_attached(currentCard,currentAttached)
			all_cards[currentCard].unrest()
			add_to_fuda(currentCard,holopower)
			removeFromLookAt(currentCard)
			currentCard = -1
			
	popup.clear()
	

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
		70: #Oshi Skill X Cost
			var input = new_text.to_int()
			if new_text.is_valid_int() and input > 0 and input <= holopower.cardList.size():
				mill(holopower,archive,input)
				var skill = all_cards[currentCard].oshi_skills[0]
				if skill[2]:
					used_sp_oshi_skill = true
					flipSPdown.rpc()
				else:
					used_oshi_skill = true
				currentCard = -1
				remove_prompt()
		71: #Oshi Skill X Cost
			var input = new_text.to_int()
			if new_text.is_valid_int() and input > 0 and input <= holopower.cardList.size():
				mill(holopower,archive,input)
				var skill = all_cards[currentCard].oshi_skills[1]
				if skill[2]:
					used_sp_oshi_skill = true
					flipSPdown.rpc()
				else:
					used_oshi_skill = true
				currentCard = -1
				remove_prompt()
		
		201: #Draw X
			var input = new_text.to_int()
			if new_text.is_valid_int() and input > 0 and input <= deck.cardList.size():
				draw(input)
				remove_prompt()
		203: #Mill X
			var input = new_text.to_int()
			if new_text.is_valid_int() and input > 0 and input <= deck.cardList.size():
				mill(deck,archive,input)
				remove_prompt()
		297: #Look At X
			var input = new_text.to_int()
			if new_text.is_valid_int() and input > 0 and input <= deck.cardList.size():
				remove_prompt()
				deck._update_looking(true,input)
				showLookAt(deck.cardList.slice(0,input))
				currentPrompt = 297
				currentFuda = deck
		
		501: #Holopower X to Archive
			var input = new_text.to_int()
			if new_text.is_valid_int() and input > 0 and input <= holopower.cardList.size():
				mill(holopower,archive,input)
				remove_prompt()

func _on_zone_clicked(zone_id):
	var actualZoneInfo = zones[zone_id]
	match currentPrompt:
		5: #Move to Back
			move_card_to_zone(currentCard,actualZoneInfo[0])
			hideZoneSelection()
		7: #Baton Pass
			switch_cards_in_zones(centerZone,actualZoneInfo[0])
			hideZoneSelection()
			used_baton_pass = true
		8: #Switch to Back
			switch_cards_in_zones(centerZone,actualZoneInfo[0])
			hideZoneSelection()
		22: #Attach Revealed Support
			var actualCard = all_cards[currentCard]
			var attachTo = find_in_zone(actualZoneInfo[0])
			actualCard.z_index = 0
			revealed.erase(currentCard)
			all_cards[attachTo].attach(actualCard)
			hideZoneSelection()
		30: #Attach Cheer
			var actualCard = all_cards[currentCard]
			var attachTo = find_in_zone(actualZoneInfo[0])
			all_cards[attachTo].attach(actualCard)
			hideZoneSelection()
		
		100: #Play
			move_card_to_zone(currentCard,actualZoneInfo[0])
			remove_from_hand(currentCard)
			all_cards[currentCard].bloomed_this_turn = true
			hideZoneSelection()
		101: #Bloom
			var actualCard = all_cards[currentCard]
			bloom_on_zone(actualCard,actualZoneInfo[0])
			remove_from_hand(currentCard)
			hideZoneSelection()
		103: #Play Hidden
			move_card_to_zone(currentCard,actualZoneInfo[0])
			remove_from_hand(currentCard,true)
			hideZoneSelection()
		121: #Attach Support
			var actualCard = all_cards[currentCard]
			var attachTo = find_in_zone(actualZoneInfo[0])
			actualCard.z_index = 0
			remove_from_hand(currentCard)
			all_cards[attachTo].attach(actualCard)
			hideZoneSelection()
		
		300: #Attach Cheer
			var actualCard = all_cards[currentCard]
			var attachTo = find_in_zone(actualZoneInfo[0])
			actualCard.z_index = 0
			all_cards[attachTo].attach(actualCard)
			hideZoneSelection()
		
		600: #Play From Deck
			remove_from_fuda(currentCard,deck)
			move_card_to_zone(currentCard,actualZoneInfo[0])
			all_cards[currentCard].bloomed_this_turn = true
			hideZoneSelection()
		601: #Bloom From Deck
			remove_from_fuda(currentCard,deck)
			var actualCard = all_cards[currentCard]
			bloom_on_zone(actualCard,actualZoneInfo[0])
			hideZoneSelection()
		602: #Attach Cheer From Deck
			remove_from_fuda(currentCard,cheerDeck)
			var actualCard = all_cards[currentCard]
			var attachTo = find_in_zone(actualZoneInfo[0])
			all_cards[attachTo].attach(actualCard)
			hideZoneSelection()
		610: #Play From Archive
			remove_from_fuda(currentCard,archive)
			move_card_to_zone(currentCard,actualZoneInfo[0])
			all_cards[currentCard].bloomed_this_turn = true
			hideZoneSelection()
		611: #Bloom From Archive
			remove_from_fuda(currentCard,archive)
			var actualCard = all_cards[currentCard]
			bloom_on_zone(actualCard,actualZoneInfo[0])
			hideZoneSelection()
		612: #Attach Cheer From Archive
			remove_from_fuda(currentCard,archive)
			var actualCard = all_cards[currentCard]
			var attachTo = find_in_zone(actualZoneInfo[0])
			all_cards[attachTo].attach(actualCard)
			hideZoneSelection()
		622: #Attach Cheer From Attach
			remove_from_attached(currentCard,currentAttached)
			var actualCard = all_cards[currentCard]
			var attachTo = find_in_zone(actualZoneInfo[0])
			all_cards[attachTo].attach(actualCard)
			hideZoneSelection()
			currentPrompt = -1
			currentAttached = null


#To be used later
func _on_die_result(num):
	pass

func _on_submit_pressed():
	_on_line_edit_text_submitted(prompt.get_node("Input/LineEdit").text)

@rpc("any_peer","call_local","reliable")
func set_is_turn(value:bool):
	if is_multiplayer_authority():
		is_turn = value
		if !preliminary_phase:
			$"CanvasLayer/End Turn".visible = value

@rpc("any_peer","call_local","reliable")
func set_player1(value:bool):
	if is_multiplayer_authority():
		player1 = value
		if player1:
			$CanvasLayer/OpponentLabel/Label.text = "Opponent Going Second"
			$CanvasLayer/OpponentLabel.visible = true
		else:
			$CanvasLayer/OpponentLabel/Label.text = "Opponent Going First"
			$CanvasLayer/OpponentLabel.visible = true

func end_turn():
	if is_turn:
		first_turn = false
		used_limited = false
		used_baton_pass = false
		collabed = false
		used_oshi_skill = false
		for actualCard in all_cards:
			if actualCard.cardType == "Holomem":
				actualCard.bloomed_this_turn = false
		emit_signal("ended_turn")

