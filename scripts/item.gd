@tool
extends RigidBody2D
class_name Item

## Emitted when this item is "dropped" (bubble is popped without being over a conveyor) 
signal item_dropped(item: Item)

## Identifier used by exits for filtering items.
@export
var identifier: StringName = &""

@onready
var _bubble: Bubble = $bubble as Bubble

@onready
var _belt_scan: Area2D = $belt_scan as Area2D

## Array of colliding Belts.
var _belts: Array[Belt] = []

## Cached belt velocities. Updated during physics frame when _belt_infos is dirty.
var _belts_velocity_max: Vector2 = Vector2.ZERO
var _belts_velocity_min: Vector2 = Vector2.ZERO

func is_bubble() -> bool:
	return _state_curr == State.BUBBLE_SETUP || _state_curr == State.BUBBLE_LAUNCH

enum State {
	BELT,
	FALL,
	BUBBLE_SETUP,
	BUBBLE_LAUNCH,
}

var _state_prev: State = State.BELT
var _state_curr: State = State.BELT
var _state_next: State = State.BELT

var _impulse: Vector2 = Vector2.ZERO

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	
	_bubble.bubble_started.connect(_on_bubble_started)
	_bubble.bubble_launched.connect(_on_bubble_launched)
	_bubble.bubble_popped.connect(_on_bubble_popped)
	
	_belt_scan.area_entered.connect(_on_belt_scan_area_entered)
	_belt_scan.area_exited.connect(_on_belt_scan_area_exited)

func _on_belt_scan_area_entered(area: Area2D) -> void:
	var belt: Belt = area as Belt
	if is_instance_valid(belt):
		_belts.append(belt)

func _on_belt_scan_area_exited(area: Area2D) -> void:
	var belt: Belt = area as Belt
	if is_instance_valid(belt):
		_belts.erase(belt)

func _on_bubble_started() -> void:
	_state_curr = State.BUBBLE_SETUP
	_state_next = State.BUBBLE_SETUP

func _on_bubble_launched(impulse: Vector2) -> void:
	_state_curr = State.BUBBLE_LAUNCH
	_state_next = State.BUBBLE_LAUNCH
	_impulse = impulse

func _on_bubble_popped() -> void:
	_state_curr = State.FALL
	_state_next = State.FALL
	linear_velocity = Vector2.ZERO

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	
	# Update belt velocity min and max.
	_belts_velocity_max = Vector2.ZERO
	_belts_velocity_min = Vector2.ZERO
	for belt: Belt in _belts:
		var belt_velocity: Vector2 = belt.get_velocity()
		_belts_velocity_max = _belts_velocity_max.max(belt_velocity)
		_belts_velocity_min = _belts_velocity_min.min(belt_velocity)

	match _state_curr:
		State.BELT:
			if _belts.is_empty():
				_state_next = State.FALL
		State.BUBBLE_LAUNCH:
			if _state_prev != State.BUBBLE_LAUNCH:
				linear_damp = 0.0
				apply_central_impulse(_impulse)
		State.FALL:
			if !_belts.is_empty():
				_state_next = State.BELT
			else:
				modulate = Color.BLACK
				item_dropped.emit(self)
	
	_state_prev = _state_curr
	_state_curr = _state_next

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	match _state_curr:
		State.BELT:
			# Seems a bit hacky to set transform position directly.
			# Changing velocity seems to be a no-go (mathematically).
			# For now, belt velocities replace velocity.
			# There's an issue with item collisions when setting position directly.
			# Items positioned inside another item causes catastrophic results.
			#var belt_velocity: Vector2 = _belt_info_velocity_min + _belt_info_velocity_max
			#state.transform = state.transform.translated(belt_velocity * state.step)
			state.linear_velocity = _belts_velocity_max + _belts_velocity_min
		State.FALL:
			state.linear_velocity = Vector2.ZERO
		State.BUBBLE_SETUP:
			state.linear_velocity = Vector2.ZERO
		State.BUBBLE_LAUNCH:
			pass

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	queue_redraw()# Not optimal but works for now.
