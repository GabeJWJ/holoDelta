extends Node2D

@export var cardID:int
@export var cardNumber:String
@export_enum("Oshi","Holomem","Cheer","Support") var cardType:String
@export var rested = false
@export var faceDown = false
@export var trulyHidden = false

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
@export var cardFront:ImageTexture
@export var artNum:int

var onTopOf = []
var attached = []

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



# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func setup_info(number,database,art_code):
	cardNumber = number
	artNum = art_code
	var data1 = database.select_rows("mainCards","cardID LIKE '" + cardNumber + "'", ["*"])[0]
	cardType = data1.cardType
	cardName = data1.cardName
	cardText = data1.cardText
	var art_data = database.select_rows("cardHasArt","cardID LIKE '" + cardNumber + "' AND art_index = " + str(art_code), ["*"])[0]
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
				oshi_color.append(row.color)
			oshi_name = PackedStringArray()
			for row in database.select_rows("oshiHasName","cardID LIKE '" + cardNumber + "'", ["*"]):
				oshi_name.append(row.name)
			oshi_skills = []
			for row in database.select_rows("oshiHasSkill","cardID LIKE '" + cardNumber + "'", ["*"]):
				oshi_skills.append([row.skillName,row.cost,bool(row.sp)])
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
				holomem_color.append(row.color)
			holomem_name = PackedStringArray()
			for row in database.select_rows("holomemHasName","cardID LIKE '" + cardNumber + "'", ["*"]):
				holomem_name.append(row.name)
			tags = PackedStringArray()
			for row in database.select_rows("holomemHasTag","cardID LIKE '" + cardNumber + "'", ["*"]):
				tags.append(row.tag)
			
			var namesText = getNamesAsText()
			if cardName != namesText:
				cardName += " (" + namesText + ")"
			if buzz:
				cardName += " buzz!"
		"Support":
			var data2 = database.select_rows("supportCards","cardID LIKE '" + cardNumber + "'", ["*"])[0]
			limited = bool(data2.limited)
			supportType = data2.supportType

func getNamesAsText():
	match cardType:
		"Oshi":
			if oshi_name.size() == 0:
				return "Nobody?"
			else:
				return "/".join(oshi_name)
		"Holomem":
			if holomem_name.size() == 0:
				return "Nobody?"
			else:
				return "/".join(holomem_name)
	
	return "idk"

func getColorsAsText():
	match cardType:
		"Oshi":
			if oshi_color.size() == 0:
				return "Colorless"
			else:
				return "/".join(oshi_color)
		"Holomem":
			if holomem_color.size() == 0:
				return "Colorless"
			else:
				return "/".join(holomem_color)
	
	return "idk"

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
			result += getColorsAsText() + " Oshi Holomem\nLife: " + str(life)
		"Holomem":
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
			result += "Holomem\nHP: " + str(hp + extra_hp - damage) + "/" + str(hp+extra_hp) +"\nTags: " + getTagsAsText()
		"Support":
			result += "Support"
			if supportType != null:
				result += " (" + supportType + ")"
	
	result += "\n\n" + cardText
	
	if cardType == "Holomem":
		if baton_pass_cost == 0:
			result += "\n\nBaton Pass: Free"
		else:
			result += "\n\nBaton Pass: " + str(baton_pass_cost) + " Any Color"
	
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
	for i in range(attached.size()):
		attached[i].position = position + Vector2(50+(20*i),0)


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
		
		for card in attached:
			card.rest()
		
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
		
		for card in attached:
			card.unrest()

func has_name_in_common(other_card):
	for potentialName in holomem_name:
		if other_card.has_name(potentialName):
			return true
	return false

func can_bloom(other_card):
	return cardType == "Holomem" and level > -1 and other_card.cardType == "Holomem" and other_card.level >=0 and other_card.level <= level and level <= other_card.level+1 and has_name_in_common(other_card) and other_card.damage < hp and !other_card.bloomed_this_turn

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

func attach(other_card):
	other_card.unrest()
	if rested:
		other_card.rest()
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
		if cardType == "Cheer":
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
