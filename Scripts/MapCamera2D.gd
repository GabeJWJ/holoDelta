class_name MapCamera2D
extends Camera2D
## A node that adds mouse, keyboard and gesture zooming, panning and dragging to [Camera2D].

## Zoom speed: multiplies [member Camera2D.zoom] each mouse wheel scroll (set to 1 to disable zooming).
@export_range(0.1, 10) var zoom_factor := 1.25
## Minimum [member Camera2D.zoom].
@export_range(0.01, 100) var zoom_min := 0.1
## Maximum [member Camera2D.zoom].
@export_range(0.01, 100) var zoom_max := 10.0
## If [code]true[/code], mouse zooming is done relative to the cursor (instead of to the center of the screen).
@export var zoom_relative := true
## If [code]true[/code], zooming can also be done with the plus and minus keys.
@export var zoom_keyboard := true

## Pan speed: adds to [member Camera2D.offset] while the cursor is near the viewport's edges (set to 0 to disable panning).
@export_range(0, 10000) var pan_speed := 250.0
## Maximum number of pixels away from the viewport's edges for the cursor to be considered near.
@export_range(0, 1000) var pan_margin := 25.0
## If [code]true[/code], panning can also be done with the arrow keys (and space bar for centering).
@export var pan_keyboard := true

## If [code]true[/code], the map can be dragged while holding the left mouse button.
@export var drag := true
## Slide after dragging: multiplies the final drag movement each second (set to 0 to stop immediately).
@export_range(0, 1) var drag_inertia := 0.1

var _tween_offset
var _tween_zoom
var _pan_direction: set = _set_pan_direction
var _pan_direction_mouse = Vector2.ZERO
var _dragging = false
var _drag_movement = Vector2()

@onready var _target_zoom = zoom

var canGo = true

func _ready():
	_pan_direction = Vector2.ZERO
	
	get_viewport().size_changed.connect(clamp_offset)

func _process(delta):
	if _drag_movement == Vector2.ZERO:
		clamp_offset(_pan_direction * pan_speed * delta / zoom)
	else:
		_drag_movement *= drag_inertia ** delta
		
		clamp_offset(-_drag_movement / zoom)
		
		if _drag_movement.length_squared() < 0.01:
			set_process(false)
			set_physics_process(false)

func _physics_process(delta):
	_process(delta)

func _input(event):
	if !canGo:
		return
	if event is InputEventMagnifyGesture:
		_change_zoom(1 + ((zoom_factor if zoom_factor > 1 else 1 / zoom_factor) - 1) * (event.factor - 1) * 2.5)
	elif event is InputEventPanGesture:
		_change_zoom(1 + (1 / zoom_factor - 1) * event.delta.y / 7.5)
	elif event is InputEventMouseButton:
		if event.pressed:
			match event.button_index:
				MOUSE_BUTTON_WHEEL_UP:
					_change_zoom(zoom_factor)
				MOUSE_BUTTON_WHEEL_DOWN:
					_change_zoom(1 / zoom_factor)
				MOUSE_BUTTON_MIDDLE:
					if drag:
						Input.set_default_cursor_shape(Input.CURSOR_DRAG) # delete to disable drag cursor
						
						_dragging = true
						_drag_movement = Vector2()
						
						set_process(false)
						set_physics_process(false)
		elif event.button_index == MOUSE_BUTTON_MIDDLE and _dragging:
			Input.set_default_cursor_shape(Input.CURSOR_ARROW)
			
			_dragging = false
			
			if _drag_movement != Vector2.ZERO || _pan_direction != Vector2.ZERO:
				set_process(process_callback == CAMERA2D_PROCESS_IDLE)
				set_physics_process(process_callback == CAMERA2D_PROCESS_PHYSICS)
	elif event is InputEventMouseMotion:
		if _pan_direction_mouse != Vector2.ZERO:
			_pan_direction -= _pan_direction_mouse
		
		_pan_direction_mouse = Vector2()
		
		if _dragging:
			if _tween_offset != null:
				_tween_offset.kill()
			
			clamp_offset(-event.relative / zoom)
			
			_drag_movement = event.relative
		elif pan_margin > 0:
			var camera_size = get_viewport_rect().size
			
			if event.position.x < pan_margin:
				_pan_direction_mouse.x -= 1
			
			if event.position.x >= camera_size.x - pan_margin:
				_pan_direction_mouse.x += 1
			
			if event.position.y < pan_margin:
				_pan_direction_mouse.y -= 1
			
			if event.position.y >= camera_size.y - pan_margin:
				_pan_direction_mouse.y += 1
		
		if _pan_direction_mouse != Vector2.ZERO:
			_pan_direction += _pan_direction_mouse
	elif event is InputEventKey:
		if zoom_keyboard && event.pressed:
			match event.keycode:
				KEY_MINUS:
					_change_zoom(zoom_factor if zoom_factor < 1 else 1 / zoom_factor, false)
				KEY_EQUAL:
					_change_zoom(zoom_factor if zoom_factor > 1 else 1 / zoom_factor, false)
		
		if pan_keyboard && !event.echo:
			match event.keycode:
				KEY_LEFT:
					_pan_direction -= Vector2(1 if event.pressed else -1, 0)
				KEY_RIGHT:
					_pan_direction += Vector2(1 if event.pressed else -1, 0)
				KEY_UP:
					_pan_direction -= Vector2(0, 1 if event.pressed else -1)
				KEY_DOWN:
					_pan_direction += Vector2(0, 1 if event.pressed else -1)
				KEY_SPACE: # delete to disable keyboard centering
					if event.pressed:
						if _tween_offset != null:
							_tween_offset.kill()
						
						offset = Vector2.ZERO

func _set_pan_direction(value):
	_pan_direction = value
	
	if _pan_direction == Vector2.ZERO || _dragging:
		set_process(false)
		set_physics_process(false)
	elif pan_speed > 0:
		set_process(process_callback == CAMERA2D_PROCESS_IDLE)
		set_physics_process(process_callback == CAMERA2D_PROCESS_PHYSICS)
		
		_drag_movement = Vector2()
		
		if _tween_offset != null:
			_tween_offset.kill()

## After changing the node's global position, set [code]offset = offset[/code] then call this to stay within limits.
func clamp_offset(relative := Vector2()):
	var camera_size = get_viewport_rect().size / zoom
	var camera_rect = Rect2(get_screen_center_position() + relative - camera_size / 2, camera_size)
	
	if camera_rect.position.x < limit_left:
		_drag_movement.x = 0
		relative.x += limit_left - camera_rect.position.x
		camera_rect.end.x += limit_left - camera_rect.position.x
	
	if camera_rect.end.x > limit_right:
		_drag_movement.x = 0
		relative.x -= camera_rect.end.x - limit_right
	
	if camera_rect.end.y > limit_bottom:
		_drag_movement.y = 0
		relative.y -= camera_rect.end.y - limit_bottom
		camera_rect.position.y -= camera_rect.end.y - limit_bottom
	
	if camera_rect.position.y < limit_top:
		_drag_movement.y = 0
		relative.y += limit_top - camera_rect.position.y
	
	if relative != Vector2.ZERO:
		offset += relative

func _change_zoom(factor, with_cursor = true):
	if factor < 1:
		if _target_zoom.x < zoom_min || is_equal_approx(_target_zoom.x, zoom_min):
			return
		
		if _target_zoom.y < zoom_min || is_equal_approx(_target_zoom.y, zoom_min):
			return
	elif factor > 1:
		if _target_zoom.x > zoom_max || is_equal_approx(_target_zoom.x, zoom_max):
			return
		
		if _target_zoom.y > zoom_max || is_equal_approx(_target_zoom.y, zoom_max):
			return
	else:
		return
	
	_target_zoom *= factor
	
	var clamped_zoom = _target_zoom
	
	clamped_zoom *= [1, zoom_min / _target_zoom.x, zoom_min / _target_zoom.y].max()
	clamped_zoom *= [1, zoom_max / _target_zoom.x, zoom_max / _target_zoom.y].min()
	
	if position_smoothing_enabled && position_smoothing_speed > 0:
		if zoom_relative && with_cursor && !is_processing() && !is_physics_processing():
			var relative_position = get_global_mouse_position() - global_position - offset
			var relative = relative_position - relative_position * zoom / clamped_zoom
			
			if _tween_offset != null:
				_tween_offset.kill()
			
			_tween_offset = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT).set_process_mode(process_callback as Tween.TweenProcessMode)
			_tween_offset.tween_property(self, 'offset', offset + relative, 2.5 / position_smoothing_speed)
		
		if _tween_zoom != null:
			_tween_zoom.kill()
		
		_tween_zoom = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT).set_process_mode(process_callback as Tween.TweenProcessMode)
		_tween_zoom.tween_method(func(value): _set_zoom_level(Vector2.ONE / value), Vector2.ONE / zoom, Vector2.ONE / clamped_zoom, 2.5 / position_smoothing_speed)
	else:
		if zoom_relative && with_cursor:
			var relative_position = get_global_mouse_position() - global_position - offset
			var relative = relative_position - relative_position * zoom / clamped_zoom
			
			zoom = clamped_zoom
			
			clamp_offset(relative)
		else:
			_set_zoom_level(clamped_zoom)

func _set_zoom_level(value):
	zoom = value
	
	clamp_offset()
