extends CanvasLayer

# This script scales the canvas layer to accomodate different screen sizes
# Currently only enabled on Android devices, using the specified margins in
# the settings, or grabbing the safe area automatically from the safe area API

@export var design_resolution := Vector2(1280, 720)

func _ready():
	if OS.has_feature("android"):
		if Settings.settings.get("AndroidAutoDetectSafeArea", true):
			apply_safe_area()
		else:
			apply_margins_from_settings()

func apply_safe_area():
	# A rect of the safe area reported by the phone in pixels
	var safe_physical := Rect2(
		Vector2(DisplayServer.get_display_safe_area().position),
		Vector2(DisplayServer.get_display_safe_area().size)
	)
	
	# A rect of how much space the game would take when scaled up to screen size
	var game_physical := get_physical_game_rect()

	# This is the rect you get when you count only the overlapping parts of
	# physical screen size and physical game size
	var usable_physical := game_physical.intersection(safe_physical)

	if usable_physical.size.x <= 0 or usable_physical.size.y <= 0:
		# Fallback: just use game area
		usable_physical = game_physical

	# Now converting from screen resolution back to game coordinates
	var viewport_size := get_viewport().get_visible_rect().size

	var phys_to_logical := viewport_size.x / game_physical.size.x

	var usable_logical := Rect2(
		(usable_physical.position - game_physical.position) * phys_to_logical,
		usable_physical.size * phys_to_logical
	)

	
	Log.logv(3, "Screen physical:", DisplayServer.screen_get_size())
	Log.logv(3, "Game physical:", get_physical_game_rect())
	Log.logv(3, "Safe physical:", safe_physical)
	Log.logv(3, "Usable physical:", usable_physical)
	Log.logv(3, "Usable logical:", usable_logical)

	# Return how much safe area we have in game coordinates
	apply_rect(usable_logical)

func get_physical_game_rect() -> Rect2:
	var screen_physical := DisplayServer.screen_get_size()
	var design := design_resolution  # 1280x720, defined in project settings

	var scale_factor = min(
		screen_physical.x / float(design.x),
		screen_physical.y / float(design.y)
	)

	var game_physical_size = Vector2(design.x, design.y) * scale_factor
	var game_physical_pos = (Vector2(screen_physical) - game_physical_size) * 0.5

	return Rect2(game_physical_pos, game_physical_size)

func apply_margins_from_settings():
	var margins = Settings.settings.get("AndroidCustomMargins", [0, 0, 0, 0])

	var screen_size := get_viewport().get_visible_rect().size
	Log.logv(3, "Screen size from viewport: ", screen_size)

	var usable := Rect2(
		Vector2(margins[0], margins[1]),
		Vector2(
			screen_size.x - margins[0] - margins[2],
			screen_size.y - margins[1] - margins[3]
		)
	)

	apply_rect(usable)

func apply_rect(usable_rect: Rect2):
	if usable_rect.size.x <= 0 or usable_rect.size.y <= 0:
		return

	# Compute uniform factor
	var uniform_factor = min(
		usable_rect.size.x / design_resolution.x,
		usable_rect.size.y / design_resolution.y
	)

	if uniform_factor <= 0:
		uniform_factor = 0.01

	var final_size = design_resolution * uniform_factor

	var centered_pos = usable_rect.position + (usable_rect.size - final_size) * 0.5

	# Apply transform to CanvasLayer
	var t := Transform2D()
	t = t.scaled(Vector2(uniform_factor, uniform_factor))
	t.origin = centered_pos

	transform = t
