extends Control

func _ready():
	if OS.has_feature("android"):
		if Settings.settings["AndroidAutoDetectSafeArea"] == true:
			apply_safe_area()
		else:
			apply_margins_from_settings()

func apply_safe_area():
	# Reset to full screen
	offset_left = 0
	offset_right = 0
	offset_top = 0
	offset_bottom = 0

	var safe := DisplayServer.get_display_safe_area()
	var screen := DisplayServer.screen_get_size()

	# safe is a Rect2i in screen coordinates
	# We want margins relative to full screen

	var left := safe.position.x
	var top := safe.position.y
	var right := screen.x - (safe.position.x + safe.size.x)
	var bottom := screen.y - (safe.position.y + safe.size.y)

	offset_left = left
	offset_top = top
	offset_right = -right
	offset_bottom = -bottom

	Log.logv(3, "Safe area: ", safe, " Screen: ", screen)
	Log.logv(3, "Margins LTRB: ", left, top, right, bottom)

func apply_margins_from_settings():
	var margins = Settings.settings["AndroidCustomMargins"]
	offset_left = margins[0]
	offset_top = margins[1]
	offset_right = -margins[2]
	offset_bottom = -margins[3]
	Log.logv(3, "Manual margins LTRB: ", margins[0], margins[1], margins[2], margins[3])
