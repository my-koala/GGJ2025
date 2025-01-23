@tool
extends Area2D
class_name Pickable

signal pressed()
signal released()

func _input_event(viewport: Viewport, event: InputEvent, shape_idx: int) -> void:
	if Engine.is_editor_hint():
		return
	
	var mouse_event: InputEventMouseButton = event as InputEventMouseButton
	if is_instance_valid(mouse_event):
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if mouse_event.pressed:
				pressed.emit()
			else:
				released.emit()
