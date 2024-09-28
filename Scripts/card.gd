extends Node2D

@export var cardID:int
@export var cardNumber:String
@export_enum("Oshi","Holomem","Cheer","Support") var cardType:String
@export var rested = false
@export var faceDown = false
@export var trulyHidden = false
@export var onstage = false

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

@export var cardName:String
@export var cardText:String
var cardFront
@export var artNum:int

var onTopOf = []
var attached = []
@export var attachedTo = -1

#Holomem Variables - Should be null otherwise
@export var level:int
@export var hp:int
@export var damage:int = 0
@export var extra_hp:int
@export var status:Array
@export var baton_pass_cost:int
@export var buzz:bool
@export var holomem_color:PackedStringArray
@export var holomem_name:PackedStringArray
@export var tags:PackedStringArray
@export var bloomed_this_turn: bool

#Oshi variables - Should be null otherwise
@export var life:int
@export var oshi_color:PackedStringArray
@export var oshi_name:PackedStringArray
@export var oshi_skills:Array

#Support variables
@export var limited:bool
@export_enum("Staff","Item","Event","Tool","Mascot","Fan") var supportType:String

#Cheer variables
@export var cheer_color:String


# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func setup_info(number,database,art_code):
	cardNumber = number
	artNum = art_code
	var data1 = database.select_rows("mainCards","cardID LIKE '" + cardNumber + "'", ["*"])
	var art_data = database.select_rows("cardHasArt","cardID LIKE '" + cardNumber + "' AND art_index = " + str(art_code), ["*"])
	if data1.is_empty() or art_data.is_empty():
		notFound = true
		match Settings.settings.Language:
			"English":
				cardFront = load("res://Sou_Desu_Ne.png")
			"日本語":
				cardFront = load("res://Sou_Desu_Ne_JP.png")
		$Front.texture = cardFront
		return
	elif art_data[0].unrevealed and !Settings.settings.AllowUnrevealed:
		notFound = true
		cardFront = load("res://spoilers.png")
		$Front.texture = cardFront
		return
	else:
		data1 = data1[0]
		art_data = art_data[0]
	cardType = data1.cardType
	
	match Settings.settings.Language:
		"English":
			cardName = data1.cardName
			cardText = data1.cardText
		"日本語":
			cardName = data1.jpName
			cardText = data1.jpText
	
	
	var image = Image.new()
	image.load_png_from_buffer(art_data.art)
	cardFront = ImageTexture.create_from_image(image)
	#$Front.texture = load("res://CardFronts/" + number + ".png")
	$Front.texture = cardFront
	
	match cardType:
		"Oshi":
			var data2 = database.select_rows("oshiCards","cardID LIKE '" + cardNumber + "'", ["*"])[0]
			life = data2.life
			oshi_color = PackedStringArray()
			for row in database.select_rows("oshiHasColor","cardID LIKE '" + cardNumber + "'", ["*"]):
				match Settings.settings.Language:
					"English":
						oshi_color.append(row.color)
					"日本語":
						oshi_color.append(Settings.to_jp[row.color])
			oshi_name = PackedStringArray()
			for row in database.select_rows("oshiHasName","cardID LIKE '" + cardNumber + "'", ["*"]):
				match Settings.settings.Language:
					"English":
						oshi_name.append(row.name)
					"日本語":
						oshi_name.append(Settings.to_jp[row.name])
			oshi_skills = []
			for row in database.select_rows("oshiHasSkill","cardID LIKE '" + cardNumber + "'", ["*"]):
				oshi_skills.append([Settings.en_or_jp(row.skillName,row.jpName),row.cost,bool(row.sp)])
		"Holomem":
			bloomed_this_turn = false
			var data2 = database.select_rows("holomemCards","cardID LIKE '" + cardNumber + "'", ["*"])[0]
			level = data2.level
			buzz = bool(data2.buzz)
			hp = data2.hp
			damage = 0
			extra_hp = 0
			baton_pass_cost = data2.batonPassCost
			status = []
			holomem_color = PackedStringArray()
			for row in database.select_rows("holomemHasColor","cardID LIKE '" + cardNumber + "'", ["*"]):
				match Settings.settings.Language:
					"English":
						holomem_color.append(row.color)
					"日本語":
						holomem_color.append(Settings.to_jp[row.color])
			holomem_name = PackedStringArray()
			for row in database.select_rows("holomemHasName","cardID LIKE '" + cardNumber + "'", ["*"]):
				match Settings.settings.Language:
					"English":
						holomem_name.append(row.name)
					"日本語":
						holomem_name.append(Settings.to_jp[row.name])
			tags = PackedStringArray()
			for row in database.select_rows("holomemHasTag","cardID LIKE '" + cardNumber + "'", ["*"]):
				match Settings.settings.Language:
					"English":
						tags.append(row.tag)
					"日本語":
						tags.append(Settings.to_jp[row.tag])
			
			var namesText = getNamesAsText()
			if cardName != namesText:
				cardName += " (" + namesText + ")"
			if buzz:
				cardName += " buzz!"
		"Support":
			var data2 = database.select_rows("supportCards","cardID LIKE '" + cardNumber + "'", ["*"])[0]
			limited = bool(data2.limited)
			match Settings.settings.Language:
				"English":
					supportType = data2.supportType
				"日本語":
					supportType = Settings.to_jp[data2.supportType]
		"Cheer":
			var data2 = database.select_rows("cheerCards","cardID LIKE '" + cardNumber + "'", ["*"])
			if data2.is_empty():
				cheer_color = "Colorless"
			else:
				cheer_color = data2[0].color

func getNamesAsText():
	match cardType:
		"Oshi":
			if oshi_name.size() == 0:
				return "Nobody?"
			else:
				match Settings.settings.Language:
					"English":
						return "/".join(oshi_name)
					"日本語":
						return "と".join(oshi_name)
		"Holomem":
			if holomem_name.size() == 0:
				return "Nobody?"
			else:
				match Settings.settings.Language:
					"English":
						return "/".join(holomem_name)
					"日本語":
						return "と".join(holomem_name)
	
	return "idk"

func getColorsAsText():
	match cardType:
		"Oshi":
			if oshi_color.size() == 0:
				match Settings.settings.Language:
					"English":
						return "Colorless"
					"日本語":
						return "無"
			else:
				match Settings.settings.Language:
					"English":
						return "/".join(oshi_color)
					"日本語":
						return "".join(oshi_color)
		"Holomem":
			if holomem_color.size() == 0:
				match Settings.settings.Language:
					"English":
						return "Colorless"
					"日本語":
						return "無"
			else:
				match Settings.settings.Language:
					"English":
						return "/".join(holomem_color)
					"日本語":
						return "".join(holomem_color)
				
	
	return "idk"

#Shoutout to whamer for the idea to add powers of 2
func getColorOrder():
	var colorToPrime = {"White":1,"Green":2,"Red":4,"Blue":8,"Purple":16,"Yellow":32,
						Settings.to_jp["White"]:1,Settings.to_jp["Green"]:2,Settings.to_jp["Red"]:4,
						Settings.to_jp["Blue"]:8,Settings.to_jp["Purple"]:16,Settings.to_jp["Yellow"]:32}
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
	if cardType == "Holomem":
		if tags.size() == 0:
			return ""
		else:
			return "#" + " #".join(tags)
	else:
		return "idk"


func full_desc():
	var result = ""
	result += cardName + "\n" + cardNumber + "\n\n"
	
	match cardType:
		"Oshi":
			match Settings.settings.Language:
				"English":
					result += getColorsAsText() + " Oshi Holomem\nLife: " + str(life)
				"日本語":
					result += getColorsAsText() + "の推しホロメン\nライフ: " + str(life)
		"Holomem":
			match Settings.settings.Language:
				"English":
					result += getColorsAsText() + " "
					match level:
						-1:
							result += "SPOT "
						0:
							result += "Debut "
						1:
							result += "1st Bloom "
						2:
							result += "2nd Bloom "
					if buzz:
						result += "Buzz "
					result += "Holomem\nHP: "
					if onstage:
						result += str(hp + extra_hp - damage) + "/"
					result += str(hp + extra_hp)
					if extra_hp > 0:
						result += " (+" + str(extra_hp) + ")"
					result += "\nTags: " + getTagsAsText()
				"日本語":
					result += getColorsAsText() + "の"
					match level:
						-1:
							result += "SPOT"
						0:
							result += "Debut"
						1:
							result += "1st"
						2:
							result += "2nd"
					if buzz:
						result += " Buzz"
					result += "ホロメン\nHP: "
					if onstage:
						result += str(hp + extra_hp - damage) + "/"
					result += str(hp + extra_hp)
					if extra_hp > 0:
						result += " (+" + str(extra_hp) + ")"
					result += "\nタグ: " + getTagsAsText()
		"Support":
			match Settings.settings.Language:
				"English":
					result += "Support "
				"日本語":
					result += "サポート"
			
			if supportType != null:
				result += "(" + supportType + ")"
	
	result += "\n\n" + cardText
	
	if cardType == "Holomem":
		match Settings.settings.Language:
			"English":
				if baton_pass_cost == 0:
					result += "\n\nBaton Pass: Free"
				else:
					result += "\n\nBaton Pass: " + str(baton_pass_cost) + " Any Color"
			"日本語":
				result += "\n\nバトンタッチ: "
				for i in baton_pass_cost:
					result += "無"
	return result


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
	if new_amount == 1:
		$Amount.visible = false
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
	other_card.status = []
	
	move_to(other_card.position)
	
	emit_signal("move_behind_request",other_card.cardID, cardID)
	for i in range(1, onTopOf.size()):
		emit_signal("move_behind_request",onTopOf[i].cardID, onTopOf[i-1].cardID)

func bloom(other_card):
	damage = other_card.damage
	extra_hp = other_card.extra_hp
	status.append_array(other_card.status)
	playOnTopOf(other_card)
	update_damage()
	bloomed_this_turn = true
	onstage = true

func unbloom():
	if onTopOf.size() == 0:
		return
	else:
		var newCard = onTopOf.pop_front()
		newCard.onTopOf = onTopOf
		onTopOf = []
		for attachCard in attached:
			newCard.attach(attachCard)
		attached = []
		newCard.status.append_array(status)
		newCard.damage = damage
		newCard.extra_hp = extra_hp
		newCard.update_damage()
		newCard.onstage = true
		status = []
		clear_damage()
		clear_extra_hp()
		unrest()
		onstage = false

func attach(other_card):
	other_card.unrest()
	attached.append(other_card)
	if attached.size() > 1:
		emit_signal("move_behind_request",other_card.cardID, attached[-2].cardID)
	else:
		emit_signal("move_behind_request",other_card.cardID,cardID)
	update_attached()


@rpc("any_peer","call_remote","reliable")
func flipDown():
	if faceDown:
		pass
	else:
		if cardType in ["Cheer","Oshi"]:
			$Front.texture = load("res://cheerBack.png")
		else:
			$Front.texture = load("res://holoBack.png")
		faceDown = true

@rpc("any_peer","call_local","reliable")
func flipUp():
	if !faceDown:
		pass
	else:
		#$Front.texture = load("res://CardFronts/" + number + ".png")
		$Front.texture = cardFront
		faceDown = false
		trulyHidden = false

@rpc("any_peer","call_local","reliable")
func trulyHide():
	if trulyHidden:
		pass
	else:
		flipDown()
		trulyHidden = true


func _on_card_button_pressed():
	emit_signal("card_clicked",cardID)


func _on_card_button_mouse_entered():
	emit_signal("card_mouse_over",cardID)


func _on_card_button_mouse_exited():
	emit_signal("card_mouse_left")


func _on_card_button_gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == 2:
		emit_signal("card_right_clicked",cardID)
