#Yes I need to come back to this
#New LookAt object that comes with multi-select and a Tree to filter the cards shown
#Should also coincedentally fix the issue with cheer getting 'stuck' on the cheer deck.
#When/if I finish it of course

extends Control

var tree_root : TreeItem
var holomem_node : TreeItem
var holomem_level_node : TreeItem
var holomem_color_node : TreeItem
var holomem_name_node : TreeItem
var holomem_tag_node : TreeItem
var holomem_extra_node : TreeItem
var support_node : TreeItem
var support_type_node : TreeItem
var support_tag_node : TreeItem
var cheer_node : TreeItem
var cheer_color_node : TreeItem

var cards_to_show : Array
var all_cards : Array

const betterButton = preload("res://Scenes/better_texture_button.tscn")
var _clicked_callable : Callable
var _info_callable : Callable

var show_tree := true:
	set(value):
		show_tree = value
		%Tree.visible = value


func _ready() -> void:
	tree_root = %Tree.create_item()

func _create_new_node(base:TreeItem, text:String) -> TreeItem:
	var new_node = %Tree.create_item(base)
	new_node.set_cell_mode(0, 1)
	new_node.set_editable(0, true)
	new_node.set_text(0, text)
	return new_node

func _clear() -> void:
	cards_to_show = []
	all_cards = []
	for child in %HBoxContainer.get_children():
		child.queue_free()
	%Tree.clear()
	holomem_node = null
	holomem_level_node = null
	holomem_color_node = null
	holomem_name_node = null
	holomem_tag_node = null
	holomem_extra_node = null
	support_node = null
	support_type_node = null
	support_tag_node = null
	cheer_node = null
	cheer_color_node = null
	tree_root = %Tree.create_item()

func _show_cards(list_of_cards : Array) -> void:
	var found_holomem = false
	var found_holomem_extra = false
	var found_support = false
	var found_support_tag = false
	var found_cheer = false
	all_cards = list_of_cards
	for actualCard in all_cards:
		var newButton = betterButton.instantiate()
		newButton.set_art(actualCard.cardNumber, actualCard.artNum)
		newButton.id = actualCard.cardID
		newButton.pressed.connect(_clicked_callable.bind(actualCard.cardID))
		newButton.mouse_entered.connect(_info_callable.bind(actualCard.cardID))
		if actualCard.cardType == "Holomem":
			found_holomem = true
			newButton.filter_info.holomem = true
			newButton.filter_info.holomem_level = actualCard.level
			newButton.filter_info.holomem_color = actualCard.holomem_color
			newButton.filter_info.holomem_name = actualCard.holomem_name
			newButton.filter_info.holomem_tag = actualCard.tags
			newButton.filter_info.holomem_extra = "buzz" if actualCard.buzz else "unlim" if actualCard.unlimited else "duo" if actualCard.holomem_name.size() > 1 else null
			if newButton.filter_info.holomem_extra:
				found_holomem_extra = true
		elif actualCard.cardType == "Support":
			found_support = true
			newButton.filter_info.support = true
			newButton.filter_info.support_type = actualCard.supportType
			newButton.filter_info.support_tag = actualCard.tags
			if newButton.filter_info.support_tag.size() > 0:
				found_support_tag = true
		elif actualCard.cardType == "Cheer":
			found_cheer = true
			newButton.filter_info.cheer = true
			newButton.filter_info.cheer_color = actualCard.cheer_color
		%HBoxContainer.add_child(newButton)
	
	if found_holomem:
		holomem_node = _create_new_node(tree_root, "TAB_HOLOMEM")
		holomem_level_node = _create_new_node(holomem_node, "LEVEL")
		holomem_color_node = _create_new_node(holomem_node, "COLOR")
		holomem_name_node = _create_new_node(holomem_node, "NAME")
		holomem_tag_node = _create_new_node(holomem_node, "TAG_PLURAL")
		if found_holomem_extra:
			holomem_extra_node = _create_new_node(holomem_node, "EXTRA")
	if found_support:
		support_node = _create_new_node(tree_root, "TAB_SUPPORT")
		support_type_node = _create_new_node(support_node, "SUPPORT_TYPE")
		if found_support_tag:
			support_tag_node = _create_new_node(support_node, "TAG_PLURAL")
	if found_cheer:
		cheer_node = _create_new_node(tree_root, "TAB_CHEER")
		cheer_color_node = _create_new_node(cheer_node, "COLOR")
