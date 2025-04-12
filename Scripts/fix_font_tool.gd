#Stolen and adapted from https://forum.godotengine.org/t/auto-text-resizing/85532
#Different languages have different text sizes. I've been managing the labels manually (bad)
#	but buttons had too much variance for one font size to work.
#I have messed around with this to get good results
#I still have no idea how this works
#And it barely does
#If you know better, go ahead

class_name FixFontTool

static func apply_text_with_corrected_max_scale(parent_size: Vector2, label: Button, text: String, scale: float = 1.0, should_correct_shadow: bool = false, shadow_offset: Vector2 = Vector2(), default_font_size = 16):
	var default_text_size = label.get_theme_font("font_size").get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, default_font_size)
	
	var scale_to_apply_to_font = (parent_size.x*scale) / default_text_size.x
	
	if Settings.settings.Language == "ko":
		scale_to_apply_to_font *= 1.5
	
	while label.get_theme_font("font_size").get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, default_font_size * scale_to_apply_to_font * scale).y > parent_size.y / scale:
		scale_to_apply_to_font *= 0.95
	
	scale_to_apply_to_font = max( 1.0 if Settings.settings.Language == "ko" else 0.5, scale_to_apply_to_font)
	
	if scale_to_apply_to_font < 1:
		label.add_theme_font_size_override("font_size", int(scale_to_apply_to_font * default_font_size * scale))
	else:
		label.add_theme_font_size_override("font_size", default_font_size)

	if should_correct_shadow:
		label.add_theme_constant_override("shadow_offset_x", int(shadow_offset.x * scale_to_apply_to_font * scale))
		label.add_theme_constant_override("shadow_offset_y", int(shadow_offset.y * scale_to_apply_to_font * scale))
