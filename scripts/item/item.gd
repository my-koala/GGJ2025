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
var _item_belt_scan: Area2D = $item_belt_scan as Area2D

## Array of colliding ItemBelts.
var _item_belts: Array[ItemBelt] = []

## Cached ItemBelt velocities. TODO: Actual caching when array is dirty.
var _item_belts_velocity_max: Vector2 = Vector2.ZERO
var _item_belts_velocity_min: Vector2 = Vector2.ZERO

func is_bubble() -> bool:
	return _bubble.is_bubble_created()

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	_item_belt_scan.area_entered.connect(_on_item_belt_scan_area_entered)
	_item_belt_scan.area_exited.connect(_on_item_belt_scan_area_exited)

func _on_item_belt_scan_area_entered(area: Area2D) -> void:
	var item_belt: ItemBelt = area as ItemBelt
	if is_instance_valid(item_belt):
		_item_belts.append(item_belt)

func _on_item_belt_scan_area_exited(area: Area2D) -> void:
	var item_belt: ItemBelt = area as ItemBelt
	if is_instance_valid(item_belt):
		_item_belts.erase(item_belt)

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	
	# Update item_belt velocity min and max.
	_item_belts_velocity_max = Vector2.ZERO
	_item_belts_velocity_min = Vector2.ZERO
	for item_belt: ItemBelt in _item_belts:
		var item_belt_velocity: Vector2 = item_belt.get_velocity()
		_item_belts_velocity_max = _item_belts_velocity_max.max(item_belt_velocity)
		_item_belts_velocity_min = _item_belts_velocity_min.min(item_belt_velocity)
	
	match _state:
		State.IDLE:
			if _item_belts.is_empty():
				print("brih")
				_state = State.DROP
		State.BUBBLE:
			if !_bubble.is_bubble_created():
				_state = State.IDLE
		State.DROP:
			# TODO: animated drop
			modulate = Color.BLACK

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	match _state:
		State.IDLE:
			state.linear_velocity = _item_belts_velocity_max + _item_belts_velocity_min
		State.BUBBLE:
			pass
		State.DROP:
			state.linear_velocity = Vector2.ZERO
