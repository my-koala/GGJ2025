@tool
extends Control
class_name Slide

## Animated Control that slides from position (0.0, 0.0) towards a direction and back using size as distance.

## If enabled, slides into position (0.0, 0.0) from direction.
## If disabled, slides out of position (0.0, 0.0) to direction.
@export
var enabled: bool = true
var _enabled: bool = true

## The direction to slide out of position.
@export
var slide_direction: Vector2 = Vector2.DOWN:
	get:
		return slide_direction
	set(value):
		slide_direction = value.normalized()

## Duration in seconds to into position.
@export_range(0.001, 8.0, 0.1)
var slide_duration_in: float = 0.25

## Duration in seconds out of position.
@export_range(0.001, 8.0, 0.1)
var slide_duration_out: float = 0.25

var _tween: Tween = null

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	_enabled = enabled
	if _enabled:
		position = Vector2.ZERO
		mouse_filter = Control.MOUSE_FILTER_STOP
	else:
		position = slide_direction * size
		mouse_filter = Control.MOUSE_FILTER_IGNORE

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	
	if _enabled == enabled:
		return
	_enabled = enabled
	
	if is_instance_valid(_tween) && _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.set_process_mode(Tween.TWEEN_PROCESS_IDLE)
	_tween.set_ease(Tween.EASE_OUT)
	_tween.set_trans(Tween.TRANS_EXPO)
	_tween.set_parallel(true)
	
	var weight: float = clampf(position.length() / size.length(), 0.0, 1.0)
	if _enabled:
		_tween.tween_property(self, "position", Vector2.ZERO, slide_duration_in * weight)
		mouse_filter = Control.MOUSE_FILTER_STOP
	else:
		_tween.tween_property(self, "position", size * slide_direction, slide_duration_out * (1.0 - weight))
		mouse_filter = Control.MOUSE_FILTER_IGNORE

