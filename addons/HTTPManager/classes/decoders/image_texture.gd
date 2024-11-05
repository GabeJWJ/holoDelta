extends "res://addons/HTTPManager/classes/decoders/image.gd"


func fetch():
	return as_texture()


func as_texture():
	var img = as_image( response_mime )
	if img:
		return ImageTexture.create_from_image(img)

	return null

