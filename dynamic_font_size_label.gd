@tool
class_name DynamicFontSizeLabel extends Label


@export_range(0.5, 5) var font_scale: float = 1.0

@export var parent: Control

@export var should_correct_shadow: bool

@export var shadow_offset: Vector2

@export var force_refresh: bool


var _previous_font_scale: float = -1.0
var _previous_viewport_size: Vector2 = Vector2()
var _previous_text: String = ""
var _previous_parent_size: Vector2 = Vector2()


func _process(__delta: float) -> void:
	if self.parent == null:
		return

	var viewport_size: Vector2 = get_viewport_rect().size
	var parent_size = self.parent.get_rect().size

	if (not Engine.is_editor_hint() 
		and
		(self._previous_font_scale != self.font_scale or
		 self._previous_text != self.text or 
		 self._previous_parent_size != parent_size)
		 or
		 self._previous_viewport_size != viewport_size or
		 self.force_refresh
	):		
		self._previous_viewport_size = viewport_size
		self._previous_font_scale = self.font_scale
		self._previous_text = self.text
		self._previous_parent_size = parent_size
		self.force_refresh = false
		

		FixFontTool.apply_text_with_corrected_max_scale(
			parent_size, 
			self, 
			self._previous_text, 
			self.font_scale, 
			self.should_correct_shadow, 
			self.shadow_offset
		)
