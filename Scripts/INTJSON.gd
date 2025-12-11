extends Node

var json = JSON.new()
var data = null

func parse(json_text:String) -> int:
	var parsed = json.parse(json_text)
	if parsed == 0:
		data = _correct_dict(json.data)
	return parsed


func _correct_dict(uncorrected_dict: Dictionary) -> Dictionary:
	for key in uncorrected_dict:
		match typeof(uncorrected_dict[key]):
			TYPE_FLOAT:
				if is_equal_approx(uncorrected_dict[key], int(uncorrected_dict[key])):
					uncorrected_dict[key] = int(uncorrected_dict[key])
			TYPE_DICTIONARY:
				uncorrected_dict[key] = _correct_dict(uncorrected_dict[key])
			TYPE_ARRAY:
				uncorrected_dict[key] = _correct_array(uncorrected_dict[key])
			
	return uncorrected_dict


func _correct_array(uncorrected_array: Array) -> Array:
	var corrected_array = []
	for item in uncorrected_array:
		match typeof(item):
			TYPE_FLOAT:
				if is_equal_approx(item, int(item)):
					corrected_array.append(int(item))
				else:
					corrected_array.append(item)
			TYPE_DICTIONARY:
				corrected_array.append(_correct_dict(item))
			TYPE_ARRAY:
				corrected_array.append(_correct_array(item))
			_:
				corrected_array.append(item)
	return corrected_array
