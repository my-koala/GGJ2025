@tool
extends RigidBody2D
class_name Item

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
	
	# problem: 1 2 -1 -2 = -1 (should be 0)
	# need to accumulate max and min values and add together
	#if is_equal_approx(signf(_belt_velocity.x), signf(belt_velocity.x)):
		#_belt_velocity.x = maxf(_belt_velocity.x, belt_velocity.x)
	#else:
		#_belt_velocity.x += belt_velocity.x
	#if is_equal_approx(signf(_belt_velocity.y), signf(belt_velocity.y)):
		#_belt_velocity.y = maxf(_belt_velocity.y, belt_velocity.y)
	#else:
		#_belt_velocity.y += belt_velocity.y

enum State {
	IDLE,
	BUBBLE_SETUP,
	BUBBLE_LAUNCH,
}
var _state_prev: State = State.IDLE
var _state_curr: State = State.IDLE

var _mouse: bool = false

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	_pickable.mouse_entered.connect(func() -> void: _mouse = true)
	_pickable.mouse_exited.connect(func() -> void: _mouse = false)

func _input(event: InputEvent) -> void:
	_bubble_launch = get_global_mouse_position().direction_to(global_position)
	
	var mouse_event: InputEventMouseButton = event as InputEventMouseButton
	if is_instance_valid(mouse_event):
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if mouse_event.pressed:
				if _mouse && (_state_prev == State.IDLE):
					# Start bubble setup.
					print("Bubble Setup")
					_state_curr = State.BUBBLE_SETUP
				elif _mouse && (_state_prev == State.BUBBLE_LAUNCH):
					print("Bubble Pop")
					# Pop the bubble.
					_state_curr = State.IDLE
			elif _state_prev == State.BUBBLE_SETUP:
				print("Bubble Launch")
				_state_curr = State.BUBBLE_LAUNCH

var _bubble_launch: Vector2 = Vector2.ZERO:
	get:
		return _bubble_launch
	set(value):
		if !_bubble_launch.is_equal_approx(value):
			_bubble_launch = value
			queue_redraw()

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	
	match _state_curr:
		State.IDLE:
			linear_damp = 16.0
			_bubble.visible = false
		State.BUBBLE_SETUP:
			linear_damp = 0.0
			_bubble.visible = true
		State.BUBBLE_LAUNCH:
			linear_damp = 0.0
			_bubble.visible = true
			if _state_prev == State.BUBBLE_SETUP:
				apply_central_impulse(_bubble_launch * 64.0)
	
	_state_prev = _state_curr

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if _state_curr == State.IDLE:
		# Seems a bit hacky to set transform position directly.
		# Changing velocity seems to be a no-go (mathematically).
		var belt_velocity: Vector2 = Vector2.ZERO
		belt_velocity = _belt_velocity_max + _belt_velocity_min
		state.transform = state.transform.translated(belt_velocity * state.step)
	
	_belt_velocity_max = Vector2.ZERO
	_belt_velocity_min = Vector2.ZERO

func _draw() -> void:
	if Engine.is_editor_hint():
		return
	
	if _state_curr == State.BUBBLE_SETUP:
		draw_set_transform(Vector2.ZERO, Vector2.DOWN.angle_to(_bubble_launch))
		draw_line(Vector2.ZERO, Vector2.DOWN * 32.0, Color.RED, 2.0, false)
		#draw_primitive()
