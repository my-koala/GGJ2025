@tool
extends Node2D
class_name Bubble

## Emitted when the player created a bubble
signal bubble_started()

## Emitted whenever the bubble has been launched by the player
signal bubble_launched(impulse: Vector2)

## Emitted when the bubble has been popped by the player
signal bubble_popped()

@export
var _pickable: Area2D

@export
var _bubble_sprite: Sprite2D

enum State {
	IDLE,
	BUBBLE_SETUP,
	BUBBLE_LAUNCH,
}

var _state_prev: State = State.IDLE
var _state_curr: State = State.IDLE
var _state_next: State = State.IDLE

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	_bubble_sprite.visible = false
	
	_pickable.mouse_entered.connect(func() -> void: _input_mouse_hovering = true)
	_pickable.mouse_exited.connect(func() -> void: _input_mouse_hovering = false)

var _input_mouse_clicked: bool = false# Mouse was clicked over pickable this physics frame.
var _input_mouse_clicking: bool = false# Mouse is currently clicked over pickable since last input event.
var _input_mouse_hovering: bool = false# Mouse is hovering over pickable since last input event.
var _input_mouse_vector: Vector2 = Vector2.ZERO# Mouse dragged vector.

func _input(event: InputEvent) -> void:
	var mouse_event: InputEventMouseButton = event as InputEventMouseButton
	if is_instance_valid(mouse_event):
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			_input_mouse_clicking = mouse_event.pressed && _input_mouse_hovering
			_input_mouse_clicked = _input_mouse_clicked || _input_mouse_clicking
	if _input_mouse_clicking:
		_input_mouse_vector = get_global_mouse_position().direction_to(global_position)
		get_viewport().set_input_as_handled()

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	match _state_curr:
		State.IDLE:
			if _input_mouse_clicked:
				_state_next = State.BUBBLE_SETUP
			
		State.BUBBLE_SETUP:
			if _state_prev != State.BUBBLE_SETUP:
				bubble_started.emit()
				_bubble_sprite.visible = true
			
			if !_input_mouse_clicking:
				_state_next = State.BUBBLE_LAUNCH
		State.BUBBLE_LAUNCH:
			if _state_prev != State.BUBBLE_LAUNCH:
				_bubble_sprite.visible = true
				# TODO: Variable launch speed based off mouse distance
				bubble_launched.emit(_input_mouse_vector * 64)
			
			if _input_mouse_clicked:
				_state_next = State.IDLE
				_bubble_sprite.visible = false
				bubble_popped.emit()
	
	# Reset mouse clicked event.
	_input_mouse_clicked = false
	
	_state_prev = _state_curr
	_state_curr = _state_next

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	queue_redraw()# Not optimal but works for now.

func _draw() -> void:
	if Engine.is_editor_hint():
		return
	# Later instead set an arrow texture visible when in State.BUBBLE_SETUP.
	if _state_curr == State.BUBBLE_SETUP:
		draw_set_transform(Vector2.ZERO, Vector2.DOWN.angle_to(_input_mouse_vector))
		draw_line(Vector2.ZERO, Vector2.DOWN * 32.0, Color.RED, 2.0, false)
