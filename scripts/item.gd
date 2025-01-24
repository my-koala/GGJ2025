@tool
extends RigidBody2D
class_name Item

## Emitted when this item is "dropped" (bubble is popped without being over a conveyor) 
signal item_dropped(item: Item)

## Identifier used by exits for filtering items.
@export
var identifier: StringName = &""

@onready
var _pickable: Area2D = $pickable as Area2D

@onready
var _bubble: Sprite2D = $bubble as Sprite2D

var _belt_velocity_max: Vector2 = Vector2.ZERO
var _belt_velocity_min: Vector2 = Vector2.ZERO

## Applies belt velocity to this item. Accumulated belt velocities are capped to velocties' maximum.
func apply_belt_velocity(belt_velocity: Vector2) -> void:
	_belt_velocity_max = _belt_velocity_max.max(belt_velocity)
	_belt_velocity_min = _belt_velocity_min.min(belt_velocity)

var _belt_count: int = 0

func increment_belt_count() -> void:
	_belt_count += 1

func decrement_belt_count() -> void:
	_belt_count -= 1

func get_belt_count() -> int:
	return _belt_count

func is_bubble() -> bool:
	return _state_curr == State.BUBBLE_SETUP || _state_curr == State.BUBBLE_LAUNCH

enum State {
	IDLE,
	FALL,
	BUBBLE_SETUP,
	BUBBLE_LAUNCH,
}

var _state_prev: State = State.IDLE
var _state_curr: State = State.IDLE
var _state_next: State = State.IDLE

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	_bubble.visible = false
	
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

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	
	match _state_curr:
		State.IDLE:
			if _state_prev != State.IDLE:
				linear_damp = 16.0
				_bubble.visible = false
			
			if get_belt_count() == 0:
				_state_next = State.FALL
			elif _input_mouse_clicked:
				_state_next = State.BUBBLE_SETUP
		State.FALL:
			if _state_prev != State.FALL:
				linear_damp = 16.0
				_bubble.visible = false
			
			if get_belt_count() > 0:
				_state_next = State.IDLE
			else:
				modulate = Color.BLACK
				item_dropped.emit(self)
			
		State.BUBBLE_SETUP:
			if _state_prev != State.BUBBLE_SETUP:
				linear_damp = 0.0
				_bubble.visible = true
			
			if !_input_mouse_clicking:
				_state_next = State.BUBBLE_LAUNCH
		State.BUBBLE_LAUNCH:
			if _state_prev != State.BUBBLE_LAUNCH:
				linear_damp = 0.0
				_bubble.visible = true
				apply_central_impulse(_input_mouse_vector * 64.0)
			
			if _input_mouse_clicked:
				_state_next = State.FALL
				# Play some bubble pop animation.
	
	# Reset mouse clicked event.
	_input_mouse_clicked = false
	
	_state_prev = _state_curr
	_state_curr = _state_next

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if _state_curr == State.IDLE:
		# Seems a bit hacky to set transform position directly.
		# Changing velocity seems to be a no-go (mathematically).
		var belt_velocity: Vector2 = Vector2.ZERO
		belt_velocity = _belt_velocity_max + _belt_velocity_min
		state.transform = state.transform.translated(belt_velocity * state.step)
	
	_belt_velocity_max = Vector2.ZERO
	_belt_velocity_min = Vector2.ZERO

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
