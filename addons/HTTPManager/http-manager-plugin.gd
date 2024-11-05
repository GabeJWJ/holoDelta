@tool
extends EditorPlugin


func _enter_tree():
	add_custom_type("HTTPManager","Node",load("res://addons/HTTPManager/classes/HTTPManager.gd"), get_editor_interface().get_base_control().get_theme_icon("HTTPRequest","EditorIcons"))


func _exit_tree():
	remove_custom_type("HTTPManager")
