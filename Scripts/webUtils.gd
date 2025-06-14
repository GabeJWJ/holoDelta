extends Node

class_name WebUtils

static func parse_query_string(query_string: String) -> Dictionary:
	var result := {}
	query_string = query_string.strip_edges().lstrip("?")
	var pairs = query_string.split("&")
	for pair in pairs:
		var kv = pair.split("=")
		if kv.size() == 2:
			result[decode_component(kv[0])] = decode_component(kv[1])
	return result
	
static func decode_component(value: String) -> String:
	if OS.has_feature("web") or OS.get_name() == "Web":
		return JavaScriptBridge.eval("decodeURIComponent('%s')" % value.replace("'", "\\'"), true)
	return value  # Fallback
