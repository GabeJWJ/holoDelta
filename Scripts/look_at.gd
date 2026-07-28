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
	all_cards = list_of_cards
	
