extends "res://addons/HTTPManager/classes/decoders/text.gd"

var json = JSON.new()

func fetch():
	var charset = response_charset
	if forced_charset != "":
		charset = forced_charset
	var text = as_text( charset )
	return json.parse_string( text )
