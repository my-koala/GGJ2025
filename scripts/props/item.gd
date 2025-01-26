@tool
extends RigidBody2D
class_name Item

# TODO:
# Bubble physics
# bubbles can bounce off of eachother, and pop on certain objects
# need to be reactive (scale wobble tween on collision given hit normal)
# while in bubble, "disable" movement physics, and track position to bubble rigidbody

## Emitted when this item is "dropped" (bubble is popped without being over a conveyor) 
signal item_dropped()

enum State {
	IDLE,
	BUBBLE,
	DROP,
	DROPPED,
}
var _state: State = State.IDLE

## Unique item identifier (should match corresponding ItemInfo).
@export
var identifier: StringName = &""

@export
var belt_speed_multiplier: float = 1.0

@onready
var _bubble: Bubble = $bubble as Bubble

@onready
var _belt_scan: Area2D = $belt_scan as Area2D

@onready
var _sprite: Sprite2D = $sprite_2d as Sprite2D

@onready
var _explosion: Explosion = $explosion as Explosion

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
	
	_bubble.read_input = false
	
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
var drop_grace_time: float = 0.001
var _drop_grace_time: float = 0.0

@export
var drop_fall_time: float = 1.0
var _drop_fall_time: float = 0.0
var _drop_fall_rotation_max: float = 0.0
var _drop_fall_rotation: float = 0.0

var _dropped: bool = false

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
	
	_bubble.read_input = !_belts.is_empty() || _bubble.is_bubble_created()
	
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
			collision_layer = 0
			collision_mask = 0
			_bubble.collision_layer = 0
			_bubble.collision_mask = 0
			if is_zero_approx(_drop_fall_rotation_max):
				_drop_fall_rotation_max = signf(randf() - 0.5) * randf_range(0.25, 0.5)
			if _drop_fall_time < drop_fall_time:
				_drop_fall_time = minf(_drop_fall_time + delta, drop_fall_time)
				_drop_fall_rotation = remap(_drop_fall_time, 0.0, drop_fall_time, 0.0, _drop_fall_rotation_max)
				var weight: float = clampf(_drop_fall_time / drop_fall_time, 0.0, 1.0)
				const drop_fall_height: float = 64.0
				const drop_fall_scale: float = 0.125
				_sprite.position.y = lerpf(0.0, drop_fall_height, weight)
				_sprite.rotation = _drop_fall_rotation
				_sprite.scale = lerpf(1.0, 0.5, weight) * Vector2.ONE
				_sprite.modulate = Color.WHITE.lerp(Color.BLACK, weight)
			else:
				_state = State.DROPPED
		State.DROPPED:
			if !_dropped:
				_dropped = true
				_sprite.modulate.a = 0.0
				_explosion.explode()
				item_dropped.emit()

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	match _state:
		State.IDLE:
			state.linear_velocity = belt_speed_multiplier * (_belts_velocity_max + _belts_velocity_min)
		State.BUBBLE:
			state.transform = _bubble.global_transform
			state.linear_velocity = Vector2.ZERO
		State.DROP:
			state.linear_velocity = Vector2.ZERO
