extends Control

@export var cardID:int
@export var cardNumber:String
@export_enum("Oshi","Holomem","Cheer","Support") var cardType:String
@export var onstage = false
@export var faceDown = false
@export var trulyHidden = false
var notFound = false

signal card_clicked(card_id)
signal card_right_clicked(card_id)
signal card_mouse_over(card_id)
signal card_mouse_left

var cardFront
var cardBack
var fullText = ""
@export var artNum:int
@export var inEditor := false

#Holomem Variables - Should be null otherwise
@export var level:int
@export var hp:int
@export var damage:int = 0
@export var offered_damage:int
@export var extra_hp:int
@export var baton_pass_cost:int
@export var default_baton_pass_cost:int
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

@export var extraNames:Array = []


#Just because the info panel is expecting this
#Better solutions exist
var onTopOf = []
var attached = []

# Android input handling
var android_click_handled := false

func setup_info(number,art_code,back=null):
	cardNumber = number
	artNum = art_code
	
	if back:
		cardBack = ImageTexture.create_from_image(back)
	
	var card_data = Database.cardData[cardNumber]
	
	%Front._initialize(cardNumber, artNum)
	cardFront = %Front.cardFront
	notFound = %Front.notFound
	
	cardType = card_data.cardType
	unlimited = card_data.cardLimit == -1
	
	if card_data.has("tags"):
		for tag in card_data.tags:
			tags.append(tag)
	
	if card_data.has("extraNames"):
		for extraName in card_data.extraNames:
			extraNames.append(extraName)
	
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
			default_baton_pass_cost = card_data.batonPassCost
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
		%Ban.visible = false
	elif num == 0:
		#Literally just the letter X
		#For some reason if I do the string "X" the pot generation picks it up as a translatable string
		#Despite not having any tr() and %Ban having auto_translate off
		#I have had to manually remove the string from template.pot genuinely probably near 100 times
		#I am LIVID
		%Ban.text = String.chr(88)
		%Ban.visible = true
	else:
		%Ban.text = str(num)
		%Ban.visible = true

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
	var colorToNum = {"White":1,"Green":2,"Red":3,"Blue":4,"Purple":5,"Yellow":6}
	match cardType:
		"Oshi":
			var result = 0.0
			for index in range(oshi_color.size()):
				result += colorToNum[oshi_color[index]] * pow(7, -index)
			return result
		"Holomem":
			var result = 0.0
			for index in range(holomem_color.size()):
				result += colorToNum[holomem_color[index]] * pow(7, -index)
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
					spSkillText += "\n\n" + Settings.trans("%s_SPSKILL_EFFECT" % cardNumber).replace("[", "[lb]")
				else:
					skillText += "\n\n" + tr("INFO_OSHI_SKILL").format({costText = costText, nameText = Settings.trans(skill[0])})
					skillText += "\n\n" + Settings.trans("%s_SKILL_EFFECT" % cardNumber).replace("[", "[lb]")
			
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
				result += "\n\n" + Settings.trans("%s_%s_EFFECT" % [cardNumber, effectKey.to_upper()]).replace("[", "[lb]")
			
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
				result += " " + Settings.trans("%s_ART_%s_NAME" % [cardNumber, art[0]]).replace("[", "[lb]")
				result += " " + str(art[2]) + ("+" if art[3] else "")
				if art[5] != null:
					result += " [img=40]res://Icons/tokkou_50_%s.png[/img]" % art[5].to_lower()
				result += "[/center]"
				if art[4]:
					result += "\n\n" + Settings.trans("%s_ART_%s_EFFECT" % [cardNumber, art[0]]).replace("[", "[lb]")
			
			var costText = ""
			for i in range(default_baton_pass_cost):
				costText += "[img=18" + (" color=ffffff70" if i >= baton_pass_cost else "") + "]res://CheerIcons/ColorlessArts.webp[/img]"
			if default_baton_pass_cost < baton_pass_cost:
				costText += " [lb]"
				for i in range(baton_pass_cost - default_baton_pass_cost):
					costText += "[img=18]res://CheerIcons/ColorlessArts.webp[/img]"
				costText += "[rb]"
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
			result += "\n\n" + Settings.trans("%s_EFFECT" % cardNumber).replace("[", "[lb]")
	
	if extraNames.size() == 1:
		result += "\n\nEXTRA: " + Settings.trans("EXTRA_EXTRANAME").format({
						cardType = Settings.trans(supportType if cardType == "Support" else cardType), extraName = Settings.trans(extraNames[0] + "_NAME") })
	
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
		%Amount.visible = false
	else:
		%Amount.visible = true
	%Amount.text = "x" + str(new_amount)

func set_amount_hidden(value : bool):
	%Amount.visible = value

func get_amount():
	return %Amount.text.substr(1).to_int()

func add_damage(amount):
	damage += amount
	if damage < 0:
		damage = 0
	if damage > 999:
		damage = 999

func clear_damage():
	damage = 0

func add_extra_hp(amount):
	extra_hp += amount
	if extra_hp < 0:
		extra_hp = 0
	if extra_hp > 999:
		extra_hp = 999

func clear_extra_hp():
	extra_hp = 0

func add_extra_baton_pass_cost(amount):
	baton_pass_cost += amount
	if baton_pass_cost < 0:
		baton_pass_cost = 0
	if baton_pass_cost > 99:
		baton_pass_cost = 99

func _on_card_button_mouse_entered():
	emit_signal("card_mouse_over",cardID)

func _on_card_button_mouse_exited():
	emit_signal("card_mouse_left")

func _on_card_button_gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		android_click_handled = true
		emit_signal("card_right_clicked",cardID)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if OS.has_feature("android"):
			# We only care about releases on Android because of timing issues
			return
		emit_signal("card_clicked",cardID)
	elif event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not OS.has_feature("android"):
			return
			# Android only handling
		if android_click_handled:
			return
		else:
			emit_signal("card_clicked",cardID)

func flipDown():
	if faceDown:
		pass
	else:
		%Front._flip(cardBack)
		faceDown = true

func flipUp():
	if !faceDown:
		pass
	else:
		%Front._flip()
		faceDown = false
		trulyHidden = false

func trulyHide():
	if trulyHidden:
		pass
	else:
		flipDown()
		trulyHidden = true

func updateBack(newBack):
	if newBack is Image:
		newBack = ImageTexture.create_from_image(newBack)
	cardBack = newBack
	if faceDown:
		%Front._flip(cardBack)

func _scale(scale_amount) -> void:
	custom_minimum_size = Vector2(309*scale_amount, 429*scale_amount)
	%CollectedForScaling.scale = Vector2(scale_amount, scale_amount)
