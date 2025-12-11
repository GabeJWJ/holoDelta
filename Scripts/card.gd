#It's the card. What do you want from me.
#Pulls double duty as the cards you see in game and the cards in the deckbuilder

extends Node2D

@export var cardID:int:
	get:
		return %CardInfo.cardID
	set(value):
		%CardInfo.cardID = value
@export var cardNumber:String:
	get:
		return %CardInfo.cardNumber
	set(value):
		%CardInfo.cardNumber = value
@export_enum("Oshi","Holomem","Cheer","Support") var cardType:String:
	get:
		return %CardInfo.cardType
	set(value):
		%CardInfo.cardType = value
@export var rested = false
@export var faceDown = false:
	get:
		return %CardInfo.faceDown
	set(value):
		%CardInfo.faceDown = value
@export var trulyHidden = false:
	get:
		return %CardInfo.trulyHidden
	set(value):
		%CardInfo.trulyHidden = value
@export var onstage = false:
	get:
		return %CardInfo.onstage
	set(value):
		%CardInfo.onstage = value
@export var fake_card = false
@export var temporary = false

var notFound = false:
	get:
		return %CardInfo.notFound
	set(value):
		%CardInfo.notFound = value

@onready var damageCounter = $DamageCounter
@onready var damageCounterText = $DamageCounter/Label
@onready var extraCounter = $ExtraCounter
@onready var extraCounterText = $ExtraCounter/Label

signal card_clicked(card_id)
signal card_right_clicked(card_id)
signal card_mouse_over(card_id)
signal card_mouse_left
signal move_behind_request(id1,id2)
signal accept_damage(card_id)
signal reject_damage(card_id)

var cardFront:
	get:
		return %CardInfo.cardFront
	set(value):
		%CardInfo.cardFront = value
var cardBack:
	get:
		return %CardInfo.cardBack
	set(value):
		%CardInfo.cardBack = value
var fullText = "":
	get:
		return %CardInfo.fullText
	set(value):
		%CardInfo.fullText = value
@export var artNum:int:
	get:
		return %CardInfo.artNum
	set(value):
		%CardInfo.artNum = value

var onTopOf = []
var attached = []
@export var attachedTo = -1

#Holomem Variables - Should be null otherwise
@export var level:int:
	get:
		return %CardInfo.level
	set(value):
		%CardInfo.level = value
@export var hp:int:
	get:
		return %CardInfo.hp
	set(value):
		%CardInfo.hp = value
@export var damage:int = 0:
	get:
		return %CardInfo.damage
	set(value):
		%CardInfo.damage = value
@export var offered_damage:int:
	get:
		return %CardInfo.offered_damage
	set(value):
		%CardInfo.offered_damage = value
@export var extra_hp:int:
	get:
		return %CardInfo.extra_hp
	set(value):
		%CardInfo.extra_hp = value
@export var baton_pass_cost:int:
	get:
		return %CardInfo.baton_pass_cost
	set(value):
		%CardInfo.baton_pass_cost = value
@export var default_baton_pass_cost:int:
	get:
		return %CardInfo.default_baton_pass_cost
	set(value):
		%CardInfo.default_baton_pass_cost = value
@export var unlimited:bool:
	get:
		return %CardInfo.unlimited
	set(value):
		%CardInfo.unlimited = value
@export var buzz:bool:
	get:
		return %CardInfo.buzz
	set(value):
		%CardInfo.buzz = value
@export var holomem_color:Array:
	get:
		return %CardInfo.holomem_color
	set(value):
		%CardInfo.holomem_color = value
@export var holomem_name:Array:
	get:
		return %CardInfo.holomem_name
	set(value):
		%CardInfo.holomem_name = value
@export var tags:Array = []:
	get:
		return %CardInfo.tags
	set(value):
		%CardInfo.tags = value
@export var bloomed_this_turn: bool:
	get:
		return %CardInfo.bloomed_this_turn
	set(value):
		%CardInfo.bloomed_this_turn = value
@export var holomem_arts: Array:
	get:
		return %CardInfo.holomem_arts
	set(value):
		%CardInfo.holomem_arts = value
@export var holomem_effects: Array:
	get:
		return %CardInfo.holomem_effects
	set(value):
		%CardInfo.holomem_effects = value

#Oshi variables - Should be null otherwise
@export var life:int:
	get:
		return %CardInfo.life
	set(value):
		%CardInfo.life = value
@export var oshi_color:Array:
	get:
		return %CardInfo.oshi_color
	set(value):
		%CardInfo.oshi_color = value
@export var oshi_name:Array:
	get:
		return %CardInfo.oshi_name
	set(value):
		%CardInfo.oshi_name = value
@export var oshi_skills:Array:
	get:
		return %CardInfo.oshi_skills
	set(value):
		%CardInfo.oshi_skills = value

#Support variables
@export var limited:bool:
	get:
		return %CardInfo.limited
	set(value):
		%CardInfo.limited = value
@export_enum("Staff","Item","Event","Tool","Mascot","Fan") var supportType:String:
	get:
		return %CardInfo.supportType
	set(value):
		%CardInfo.supportType = value

#Cheer variables
@export var cheer_color:String:
	get:
		return %CardInfo.cheer_color
	set(value):
		%CardInfo.cheer_color = value

@export var extraNames:Array = []:
	get:
		return %CardInfo.extraNames
	set(value):
		%CardInfo.extraNames = value


func setup_info(number,art_code,back=null):
	%CardInfo.setup_info(number, art_code, back)


func set_ban(num: int):
	%CardInfo.set_ban(num)

func getNamesAsText():
	return %CardInfo.getNamesAsText()

func getColorsAsText():
	return %CardInfo.getColorsAsText()

func getColorOrder():
	return %CardInfo.getColorOrder()

func getTagsAsText():
	return %CardInfo.getTagsAsText()


func full_desc():
	return %CardInfo.full_desc()


func get_card_name():
	return %CardInfo.get_card_name()


func is_color(color):
	return %CardInfo.is_color(color)

func is_colorless():
	return %CardInfo.is_colorless()

func has_name(name_check):
	return %CardInfo.has_name(name_check)

func has_tag(tag_check):
	return %CardInfo.has_tag(tag_check)


func update_amount(new_amount):
	%CardInfo.update_amount(new_amount)

func set_amount_hidden(value : bool):
	%CardInfo.set_amount_hidden(value)

func get_amount():
	return %CardInfo.get_amount()


func update_damage():
	if damage == 0:
		damageCounter.visible = false
	else:
		damageCounterText.text = str(damage)
		damageCounter.visible = true
	if extra_hp == 0:
		extraCounter.visible = false
	else:
		extraCounterText.text = str(extra_hp)
		extraCounter.visible = true

func add_damage(amount):
	%CardInfo.add_damage(amount)
	update_damage()

func clear_damage():
	%CardInfo.clear_damage()
	update_damage()

func add_extra_hp(amount):
	%CardInfo.add_extra_hp(amount)
	update_damage()

func clear_extra_hp():
	%CardInfo.clear_extra_hp()
	update_damage()

func add_extra_baton_pass_cost(amount):
	%CardInfo.add_extra_baton_pass_cost(amount)

func update_attached():
	var cheer_i = 0
	var support_i = 0
	for attached_card in attached:
		attached_card.attachedTo = cardID
		if attached_card.cardType == "Cheer":
			if rested:
				attached_card.position = position - Vector2(50, -10 - 35*(cheer_i+1))
			else:
				attached_card.position = position + Vector2(0, 35*(cheer_i+1))
			cheer_i += 1
		else:
			if rested:
				attached_card.position = position - Vector2(50-(20*support_i), 50)
			else:
				attached_card.position = position + Vector2(50+(20*support_i),0)
			support_i += 1


func move_to(new_position):
	position = new_position
	
	if rested:
		position += Vector2(50,50)
	
	for card in onTopOf:
		card.position = position
	
	update_attached()


func rest():
	if rested:
		pass
	else:
		rotation = 1.571
		position += Vector2(50,50)
		rested = true
		
		damageCounter.rotation = -1.571
		extraCounter.rotation = -1.571
		
		for card in onTopOf:
			card.rest()
		
		update_attached()
		
func unrest():
	if !rested:
		pass
	else:
		rotation = 0
		position -= Vector2(50,50)
		rested = false
		
		damageCounter.rotation = 0
		extraCounter.rotation = 0
		
		for card in onTopOf:
			card.unrest()
		
		update_attached()

func has_name_in_common(other_card):
	for potentialName in holomem_name:
		if other_card.has_name(potentialName):
			return true
	return false

func can_bloom(other_card):
	if cardType == "Holomem" and level > 0 and other_card.cardType == "Holomem" and other_card.level >=0 and has_name_in_common(other_card) and other_card.damage < hp:
		if other_card.level <= level:
			var difference = level - other_card.level
			if difference <= 1:
				if other_card.bloomed_this_turn:
					return Settings.bloomCode.Instant
				else:
					return Settings.bloomCode.OK
			else:
				return Settings.bloomCode.Skip
	return Settings.bloomCode.No

func playOnTopOf(other_card):
	if other_card.rested:
		rest()
		other_card.position -= Vector2(50,50)
	
	onTopOf.append(other_card)
	onTopOf.append_array(other_card.onTopOf)
	other_card.onTopOf = []
	for att in other_card.attached:
		attach(att)
	other_card.attached = []
	other_card.clear_damage()
	other_card.clear_extra_hp()
	
	var newPos = other_card.position
	move_to(newPos)
	if rested:
		newPos += Vector2(50, 50)
	position = newPos - Vector2(0,100)
	var tween = get_tree().create_tween()
	tween.tween_property(self, "position", newPos, 0.1)
	
	emit_signal("move_behind_request",other_card.cardID, cardID)
	for i in range(1, onTopOf.size()):
		emit_signal("move_behind_request",onTopOf[i].cardID, onTopOf[i-1].cardID)

func bloom(other_card):
	damage = other_card.damage
	extra_hp = other_card.extra_hp
	playOnTopOf(other_card)
	update_damage()
	bloomed_this_turn = true
	onstage = true

func unbloom():
	if onTopOf.size() == 0:
		return null
	else:
		var newCard = onTopOf.pop_front()
		newCard.onTopOf = onTopOf
		onTopOf = []
		for attachCard in attached:
			newCard.attach(attachCard)
		attached = []
		newCard.damage = damage
		newCard.extra_hp = extra_hp
		newCard.update_damage()
		newCard.onstage = true
		clear_damage()
		clear_extra_hp()
		unrest()
		return newCard

func attach(other_card):
	other_card.unrest()
	attached.append(other_card)
	if attached.size() > 1:
		emit_signal("move_behind_request",other_card.cardID, attached[-2].cardID)
	else:
		emit_signal("move_behind_request",other_card.cardID,cardID)
	update_attached()


func flipDown():
	%CardInfo.flipDown()

func flipUp():
	%CardInfo.flipUp()

func trulyHide():
	%CardInfo.trulyHide()

func updateBack(newBack):
	%CardInfo.updateBack(newBack)


func showNotice():
	var tween = get_tree().create_tween()
	tween.tween_property($Notice,"modulate",Color(1,1,1,1),0.1)
	tween.tween_interval(0.2)
	tween.tween_property($Notice,"modulate",Color(1,1,1,0),0.1)

func hitAndBack(hitPos):
	var differencePos = hitPos - position
	var tween = get_tree().create_tween()
	tween.tween_property(self,"position",position + (differencePos * -0.2),0.05)
	tween.tween_interval(0.01)
	tween.tween_property(self,"position",position + (0.8 * differencePos), 0.1)
	tween.tween_interval(0.05)
	tween.tween_property(self,"position",position, 0.15)
	tween.tween_callback(set_z_index.bind(z_index))
	z_index = 5

func _on_card_info_pressed(_id):
	emit_signal("card_clicked",cardID)

func _on_card_info_mouse_entered(_id):
	emit_signal("card_mouse_over",cardID)

func _on_card_info_mouse_exited():
	emit_signal("card_mouse_left")

func _on_card_info_gui_input(_id):
	emit_signal("card_right_clicked",cardID)


func offer_damage(newDamage):
	offered_damage += newDamage
	$PotentialDamage.text = str(offered_damage)
	$PotentialDamageRested.text = str(offered_damage)
	if rested:
		$PotentialDamageRested.visible = true
	else:
		$PotentialDamage.visible = true

func _on_accept_mouse_entered():
	$PotentialDamage/Accept.modulate.a = 1

func _on_accept_mouse_exited():
	$PotentialDamage/Accept.modulate.a = 0.5

func _on_reject_mouse_entered():
	$PotentialDamage/Reject.modulate.a = 1

func _on_reject_mouse_exited():
	$PotentialDamage/Reject.modulate.a = 0.5

func _on_accept_rested_mouse_entered():
	$PotentialDamageRested/Accept.modulate.a = 1

func _on_accept_rested_mouse_exited():
	$PotentialDamageRested/Accept.modulate.a = 0.5

func _on_reject_rested_mouse_entered():
	$PotentialDamageRested/Reject.modulate.a = 1

func _on_reject_rested_mouse_exited():
	$PotentialDamageRested/Reject.modulate.a = 0.5


func _on_accept_pressed():
	emit_signal("accept_damage",cardID)

func _on_reject_pressed():
	offered_damage = 0
	$PotentialDamage.visible = false
	$PotentialDamageRested.visible = false
	emit_signal("reject_damage",cardID)
