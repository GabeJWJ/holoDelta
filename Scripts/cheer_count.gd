extends Control

var cheer_texture:
	get:
		return %CheerBase.texture
	set(value):
		%CheerBase.texture = value

var count = 20:
	set(value):
		%Count.text = str(value)
