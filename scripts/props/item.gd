@tool
extends RigidBody2D
class_name Item

# TODO:
# Bubble physics
# bubbles can bounce off of eachother, and pop on certain objects
# need to be reactive (scale wobble tween on collision given hit normal)
# while in bubble, "disable" movement physics, and track position to bubble rigidbody

## Emitted when this item is "dropped" (bubble is popped without being over a conveyor) 
signal item_dropped(item: Item)

enum State {
	IDLE,
	BUBBLE,
	DROP,
}
var _state: State = State.IDLE

## Identifier used by exits for filtering items.
@export
var identifier: StringName = &""

@onready
var _bubble: Bubble = $bubble as Bubble

@onready
var _belt_scan: Area2D = $belt_scan as Area2D

## Array of colliding Belts.
var _belts: Array[Belt] = []

## Cached Belt velocities. TODO: Actual caching when array is dirty.
var _belts_velocity_max: Vector2 = Vector2.ZERO
var _belts_velocity_min: Vector2 = Vector2.ZERO

func is_bubble() -> bool:
	return _bubble.is_bubble_created()

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	_belt_scan.area_entered.connect(_on_belt_scan_area_entered)
	_belt_scan.area_exited.connect(_on_belt_scan_area_exited)
	
	add_collision_exception_with(_bubble)

func _on_belt_scan_area_entered(area: Area2D) -> void:
	var belt: Belt = area as Belt
	if is_instance_valid(belt):
		_belts.append(belt)

func _on_belt_scan_area_exited(area: Area2D) -> void:
	var belt: Belt = area as Belt
	if is_instance_valid(belt):
		_belts.erase(belt)

@export
var drop_grace_time: float = 0.1
var _drop_grace_time: float = 0.0

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
	
	match _state:
		State.IDLE:
			if _bubble.is_bubble_created():
				_state = State.BUBBLE
			elif _belts.is_empty():
				_drop_grace_time += delta
				if _drop_grace_time > drop_grace_time:
					_state = State.DROP
			else:
				_drop_grace_time = 0.0
		State.BUBBLE:
			if !_bubble.is_bubble_created():
				_state = State.IDLE
		State.DROP:
			# TODO: animated drop
			modulate = Color.BLACK

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	match _state:
		State.IDLE:
			state.linear_velocity = _belts_velocity_max + _belts_velocity_min
		State.BUBBLE:
			state.transform = _bubble.global_transform
			state.linear_velocity = Vector2.ZERO
		State.DROP:
			state.linear_velocity = Vector2.ZERO
