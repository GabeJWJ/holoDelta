#It's the card. What do you want from me.
#Pulls double duty as the cards you see in game and the cards in the deckbuilder

extends Node2D

@export var cardID:int
@export var cardNumber:String
@export_enum("Oshi","Holomem","Cheer","Support") var cardType:String
@export var rested = false
@export var faceDown = false
@export var trulyHidden = false
@export var onstage = false
@export var fake_card = false
@export var temporary = false

var notFound = false

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

var cardFront
var cardBack
var fullText = ""
@export var artNum:int
@export var inEditor := false

var onTopOf = []
var attached = []
@export var attachedTo = -1

#Holomem Variables - Should be null otherwise
@export var level:int
@export var hp:int
@export var damage:int = 0
@export var offered_damage:int
@export var extra_hp:int
@export var baton_pass_cost:int
@export var unlimited:bool
@export var buzz:bool
@export var holomem_color:Array
@export var holomem_name:Array
@export var tags:Array = []
@export var bloomed_this_turn: bool
@export var holomem_arts: Array
@export var holomem_effects: Array

#Oshi variables - Should be null otherwise
@export var life:int
@export var oshi_color:Array
@export var oshi_name:Array
@export var oshi_skills:Array

#Support variables
@export var limited:bool
@export_enum("Staff","Item","Event","Tool","Mascot","Fan") var supportType:String

#Cheer variables
@export var cheer_color:String


func setup_info(number,art_code,back=null):
	cardNumber = number
	artNum = art_code
	
	if back:
		cardBack = ImageTexture.create_from_image(back)
	
	var card_data = Database.cardData[cardNumber]
	
	if card_data.is_empty():
		notFound = true
		match Settings.settings.Language:
			"ja":
				cardFront = load("res://Sou_Desu_Ne_JP.png")
			_:
				cardFront = load("res://Sou_Desu_Ne.png")
		$Front.texture = cardFront
		return
	elif "ja" in card_data.cardArt[str(artNum)] and card_data.cardArt[str(artNum)].ja.unrevealed and !Settings.settings.AllowUnrevealed:
		notFound = true
		cardFront = load("res://spoilers.png")
		$Front.texture = cardFront
		return
	cardType = card_data.cardType
	unlimited = card_data.cardLimit == -1
	
	#IF YOU CHANGE THIS CODE ALSO CHANGE IT IN DECK_INFO
	var lang_code = "ja" if "ja" in card_data.cardArt[str(artNum)] else "en"
	if 'en' in card_data.cardArt[str(artNum)] and Settings.settings.OnlyEN:
		lang_code = 'en'
	else:
		for lang in card_data.cardArt[str(artNum)]:
			if Settings.settings.UseCardLanguage and lang == Settings.settings.Language and (Settings.settings.AllowProxies or !bool(card_data.cardArt[str(artNum)][lang].proxy)):
				lang_code = lang
	
	if cardNumber in Database.cardArts and int(artNum) in Database.cardArts[cardNumber] and lang_code in Database.cardArts[cardNumber][int(artNum)]:
		cardFront = Database.cardArts[cardNumber][int(artNum)][lang_code]
		$Front.texture = cardFront
	else:
		print(cardNumber, " ", artNum, " ", lang_code)
	#YES I SHOULDN'T JUST COPY-PASTE CODE - THIS ONE WAS TRICKY TO SEPARATE INTO ITS OWN THING
	
	if card_data.has("tags"):
		for tag in card_data.tags:
			tags.append(tag)
	
	match cardType:
		"Oshi":
			life = card_data.life
			oshi_color = []
			for color in card_data.color:
				oshi_color.append(color)
			oshi_name = []
			for name in card_data.name:
				oshi_name.append(name)
			oshi_skills = []
			for skill in card_data.skills:
				if bool(skill.sp):
					oshi_skills.append(["%s_SPSKILL_NAME" % cardNumber,skill.cost,bool(skill.sp)])
				else:
					oshi_skills.append(["%s_SKILL_NAME" % cardNumber,skill.cost,bool(skill.sp)])
				
		"Holomem":
			bloomed_this_turn = false
			level = card_data.level
			buzz = bool(card_data.buzz)
			hp = card_data.hp
			damage = 0
			offered_damage = 0
			extra_hp = 0
			baton_pass_cost = card_data.batonPassCost
			holomem_color = []
			for color in card_data.color:
				holomem_color.append(color)
			holomem_name = []
			for name in card_data.name:
				holomem_name.append(name)
			holomem_arts = []
			for art in card_data.arts:
				var cost_dict = {"White": 0, "Green": 0, "Red": 0, "Blue": 0, "Purple": 0, "Yellow": 0, "Any" : 0}
				for chr in art.cost:
					match chr:
						"W":
							cost_dict.White += 1
						"G":
							cost_dict.Green += 1
						"R":
							cost_dict.Red += 1
						"B":
							cost_dict.Blue += 1
						"P":
							cost_dict.Purple += 1
						"Y":
							cost_dict.Yellow += 1
						"N":
							cost_dict.Any += 1
				holomem_arts.append([art.artIndex,cost_dict,art.damage,bool(art.hasPlus),bool(art.hasEffect),null if !art.has("advantage") else art.advantage])
			holomem_arts.sort_custom(func(a,b): return a[0] < b[0]) #Order arts by index
			holomem_effects = []
			if card_data.has("effect"):
				holomem_effects.append(card_data.effect)
		"Support":
			limited = bool(card_data.limited)
			supportType = card_data.supportType
		"Cheer":
			if card_data.has("color"):
				cheer_color = card_data.color
			else:
				cheer_color = "COLORLESS"
	
	fullText = full_desc()

func set_ban(num: int):
	if num < 0:
		$Ban.visible = false
	elif num == 0:
		$Ban.text = "X"
		$Ban.visible = true
	else:
		$Ban.text = str(num)
		$Ban.visible = true

func getNamesAsText():
	match cardType:
		"Oshi":
			if oshi_name.size() == 0:
				return tr("NOBODY")
			else:
				return tr("NAMESEP").join(oshi_name.map(Settings.trans))
		"Holomem":
			if holomem_name.size() == 0:
				return tr("NOBODY")
			else:
				return tr("NAMESEP").join(holomem_name.map(Settings.trans))
	
	return "idk"

func getColorsAsText():
	match cardType:
		"Oshi":
			if oshi_color.size() == 0:
				return tr("COLORLESS")
			else:
				return tr("COLORSEP").join(oshi_color.map(Settings.trans))
		"Holomem":
			if holomem_color.size() == 0:
				return tr("COLORLESS")
			else:
				return tr("COLORSEP").join(holomem_color.map(Settings.trans))
				
	
	return "idk"

#Shoutout to whamer for the idea to add powers of 2
func getColorOrder():
	var colorToPrime = {"White":1,"Green":2,"Red":4,"Blue":8,"Purple":16,"Yellow":32}
	match cardType:
		"Oshi":
			var result = 0
			for color in oshi_color:
				result += colorToPrime[color]
			return result
		"Holomem":
			var result = 0
			for color in holomem_color:
				result += colorToPrime[color]
			return result
	return 0

func getTagsAsText():
	if tags.size() == 0:
		return ""
	else:
		return "#" + " #".join(tags.map(Settings.trans))


func full_desc():
	var result = Settings.trans("%s_NAME" % cardNumber)
	if cardType in ["Holomem", "Oshi"]:
		var namesText = getNamesAsText()
		if result != namesText:
			result += " (%s)" % namesText
		if cardType == "Holomem" and buzz:
			result += " " + tr("NAME_BUZZ")
	result += "\n" + cardNumber + "\n\n"
	
	match cardType:
		"Oshi":
			result += tr("INFO_OSHI").format({colorText = getColorsAsText(), life = life, tagsText = "\n" + getTagsAsText()})
			var skillText = ""
			var spSkillText = ""
			for skill in oshi_skills:
				var costText = str(skill[1])
				if skill[1] == -1:
					costText = "X"
				if skill[2]:
					spSkillText += "\n\n" + tr("INFO_OSHI_SPSKILL").format({costText = costText, nameText = Settings.trans(skill[0])})
					spSkillText += "\n\n" + Settings.trans("%s_SPSKILL_EFFECT" % cardNumber)
				else:
					skillText += "\n\n" + tr("INFO_OSHI_SKILL").format({costText = costText, nameText = Settings.trans(skill[0])})
					skillText += "\n\n" + Settings.trans("%s_SKILL_EFFECT" % cardNumber)
			
			result += skillText
			result += spSkillText
				
		"Holomem":
			var infoLevels = {-1: tr("INFO_SPOT"), 0: tr("INFO_DEBUT"), 1: tr("INFO_1ST"), 2: tr("INFO_2ND")}[level]
			var infoBuzz = tr("INFO_BUZZ") if buzz else ""
			var infoHP = (str(hp + extra_hp - damage) + "/" if onstage else "") + str(hp + extra_hp) + (" (+" + str(extra_hp) + ")" if extra_hp > 0 else "")
			
			result += tr("INFO_HOLOMEM_1").format({colorText = getColorsAsText(), levelText = infoLevels, buzzText = infoBuzz, hpText = infoHP, tagsText = getTagsAsText()})
			for effect in holomem_effects:
				var effectKey = effect
				result += "\n\n[center]"
				match effect:
					"Gift":
						result += "[img=60]Icons/gift.png[/img]"
					"Bloom Effect":
						effectKey = "Bloom"
						result += "[img=80]Icons/bloomEF.png[/img]"
					"Collab Effect":
						effectKey = "Collab"
						result += "[img=80]Icons/collabEF.png[/img]"
				
				result += " " + Settings.trans("%s_%s_NAME" % [cardNumber, effectKey.to_upper()]) + "[/center]"
				result += "\n\n" + Settings.trans("%s_%s_EFFECT" % [cardNumber, effectKey.to_upper()])
			
			result += "\n"
			
			for art in holomem_arts:
				result += "\n\n[center]"
				for i in range(art[1].White):
					result += "[img=18]res://CheerIcons/WhiteArts.webp[/img]"
				for i in range(art[1].Green):
					result += "[img=18]res://CheerIcons/GreenArts.webp[/img]"
				for i in range(art[1].Red):
					result += "[img=18]res://CheerIcons/RedArts.webp[/img]"
				for i in range(art[1].Blue):
					result += "[img=18]res://CheerIcons/BlueArts.webp[/img]"
				for i in range(art[1].Purple):
					result += "[img=18]res://CheerIcons/PurpleArts.webp[/img]"
				for i in range(art[1].Yellow):
					result += "[img=18]res://CheerIcons/YellowArts.webp[/img]"
				for i in range(art[1].Any):
					result += "[img=18]res://CheerIcons/ColorlessArts.webp[/img]"
				result += " " + Settings.trans("%s_ART_%s_NAME" % [cardNumber, art[0]])
				result += " " + str(art[2]) + ("+" if art[3] else "")
				if art[5] != null:
					result += " [img=40]res://Icons/tokkou_50_%s.png[/img]" % art[5].to_lower()
				result += "[/center]"
				if art[4]:
					result += "\n\n" + Settings.trans("%s_ART_%s_EFFECT" % [cardNumber, art[0]])
			
			var costText = ""
			for i in range(baton_pass_cost):
				costText += "[img=18]res://CheerIcons/ColorlessArts.webp[/img]"
			if costText == "":
				costText = tr("INFO_NOBATONPASSCOST")
			result += "\n\n" + tr("INFO_HOLOMEM_2").format({costText = costText})
			
			if unlimited:
				result += "\n\nEXTRA: " + Settings.trans("EXTRA_UNLIM")
			if level == -1:
				result += "\n\nEXTRA: " + Settings.trans("EXTRA_SPOT")
			if buzz:
				result += "\n\nEXTRA: " + Settings.trans("EXTRA_BUZZ")
			if holomem_name.size() == 2:
				result += "\n\nEXTRA: " + Settings.trans("EXTRA_DUO").format({firstName = holomem_name[0], secondName = holomem_name[1]})
		"Support":
			result += tr("INFO_SUPPORT").format({supportText = Settings.trans("Support"), typeText = Settings.trans(supportType), tagsText = "\n" + getTagsAsText()})
			if limited:
				result += "\n\n" + tr("INFO_LIMITED")
			result += "\n\n" + Settings.trans("%s_EFFECT" % cardNumber)
	
	return result

func get_card_name():
	return Settings.trans("%s_NAME" % cardNumber)


func is_color(color):
	match cardType:
		"Oshi":
			return color in oshi_color
		"Holomem":
			return color in holomem_color
	return false

func is_colorless():
	match cardType:
		"Oshi":
			return oshi_color.size() == 0
		"Holomem":
			return holomem_color.size() == 0
	return false

func has_name(name_check):
	match cardType:
		"Oshi":
			return name_check in oshi_name
		"Holomem":
			return name_check in holomem_name
	return false

func has_tag(tag_check):
	return tag_check in tags


func update_amount(new_amount):
	if new_amount <= 0:
		$Amount.visible = false
	else:
		$Amount.visible = true
	$Amount.text = "x" + str(new_amount)

func set_amount_hidden(value : bool):
	$Amount.visible = value

func get_amount():
	return $Amount.text.substr(1).to_int()


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
	damage += amount
	if damage < 0:
		damage = 0
	if damage > 999:
		damage = 999
	update_damage()

func clear_damage():
	damage = 0
	update_damage()

func add_extra_hp(amount):
	extra_hp += amount
	if extra_hp < 0:
		extra_hp = 0
	if extra_hp > 999:
		extra_hp = 999
	update_damage()

func clear_extra_hp():
	extra_hp = 0
	update_damage()

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
	if faceDown:
		pass
	else:
		$Front.texture = cardBack
		faceDown = true

func flipUp():
	if !faceDown:
		pass
	else:
		$Front.texture = cardFront
		faceDown = false
		trulyHidden = false

func trulyHide():
	if trulyHidden:
		pass
	else:
		flipDown()
		trulyHidden = true

func updateBack(newBack):
	cardBack = newBack
	if faceDown:
		$Front.texture = cardBack


func _on_card_button_pressed():
	emit_signal("card_clicked",cardID)

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


func _on_card_button_mouse_entered():
	emit_signal("card_mouse_over",cardID)


func _on_card_button_mouse_exited():
	emit_signal("card_mouse_left")


func _on_card_button_gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == 2:
		emit_signal("card_right_clicked",cardID)


func offer_damage(newDamage):
	offered_damage += newDamage
	$PotentialDamage.text = str(offered_damage)
	$PotentialDamage.visible = true

func _on_accept_mouse_entered():
	$PotentialDamage/Accept.modulate.a = 1

func _on_accept_mouse_exited():
	$PotentialDamage/Accept.modulate.a = 0.5

func _on_reject_mouse_entered():
	$PotentialDamage/Reject.modulate.a = 1

func _on_reject_mouse_exited():
	$PotentialDamage/Reject.modulate.a = 0.5


func _on_accept_pressed():
	emit_signal("accept_damage",cardID)

func _on_reject_pressed():
	offered_damage = 0
	$PotentialDamage.visible = false
	emit_signal("reject_damage",cardID)
