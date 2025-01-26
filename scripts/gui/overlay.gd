@tool
extends Control
class_name Overlay

## Animated Control overlay with modulate alpha fade in/out and mouse filtering.

## If enabled, modulate alpha is faded to opaque and mouse filter is set to stop.
## If disabled, modulate alpha is faded to transparent and mouse filter is set to pass.
@export
var enabled: bool = true
var _enabled: bool = true

## Duration in seconds to fade modulate alpha to opaque.
@export_range(0.001, 8.0, 0.1)
var fade_duration_in: float = 0.375

## Duration in seconds to fade modulate alpha to transparent.
@export_range(0.001, 8.0, 0.1)
var fade_duration_out: float = 0.375

var _tween: Tween = null

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	_enabled = enabled
	if _enabled:
		modulate.a = 1.0
		mouse_filter = Control.MOUSE_FILTER_STOP
	else:
		modulate.a = 0.0
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
	_tween.set_trans(Tween.TRANS_CUBIC)
	_tween.set_parallel(true)
	
	var weight: float = modulate.a / 1.0
	if _enabled:
		_tween.tween_property(self, "modulate:a", 1.0, fade_duration_in * weight)
		mouse_filter = Control.MOUSE_FILTER_STOP
	else:
		_tween.tween_property(self, "modulate:a", 0.0, fade_duration_in * (1.0 - weight))
		mouse_filter = Control.MOUSE_FILTER_IGNORE
