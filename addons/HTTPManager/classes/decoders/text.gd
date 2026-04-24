extends "res://addons/HTTPManager/classes/decoders/application_octet-stream.gd"


func fetch():
	var charset = response_charset
	if forced_charset != "":
		charset = forced_charset
	return as_text( charset )


func as_text( charset ):
	match charset:
		"utf-8":
			return response_body.get_string_from_utf8()
		"utf-16":
			return response_body.get_string_from_utf16()
		"utf-32":
			return response_body.get_string_from_utf32()
		_:
			return response_body.get_string_from_ascii()
