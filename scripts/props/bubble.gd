@tool
extends RigidBody2D
class_name Bubble

# TODO: Bubble collisions.

# NOTE: state.get_contact_impulse is broken: https://github.com/godotengine/godot/issues/73541

## Emitted when the bubble is blown.
signal bubble_created()

## Emitted when the bubble has been launched.
signal bubble_launched(impulse: Vector2)

## Emitted when the bubble has been popped, either by bubble_destroy, input, or physics collision.
signal bubble_destroyed()

## If read input is enabled, then input for enabling/disabling bubble is performed.
@export
var read_input: bool = true

@export
var can_bubble: bool = true

var _input_mouse_clicked: bool = false# Mouse was clicked over pickable this physics frame.
var _input_mouse_clicking: bool = false# Mouse is currently clicked over pickable since last input event.
var _input_mouse_hovering: bool = false# Mouse is hovering over pickable since last input event.
var _input_mouse_vector: Vector2 = Vector2.ZERO# Mouse dragged vector.

@onready
var _sprite: Sprite2D = $sprite_2d as Sprite2D

@onready
var _collision_shape: CollisionShape2D = $collision_shape_2d as CollisionShape2D

@onready
var _pickable: Area2D = $pickable as Area2D

var _bubble_created: bool = false
func is_bubble_created() -> bool:
	return _bubble_created

func bubble_create() -> void:
	if !can_bubble:
		return
	if !_bubble_created:
		_bubble_created = true
		_sprite.visible = true
		_bubble_launched = false
		_collision_shape.disabled = false
		bubble_created.emit()

var _bubble_launched: bool = false
func bubble_launch(impulse: Vector2) -> void:
	if _bubble_created && !_bubble_launched:
		_bubble_launched = true
		apply_central_impulse(impulse)
		bubble_launched.emit(impulse)

func bubble_destroy() -> void:
	if _bubble_created:
		_bubble_created = false
		_sprite.visible = false
		_collision_shape.disabled = true
		bubble_destroyed.emit()

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	_sprite.visible = false
	_collision_shape.disabled = true
	
	_pickable.mouse_entered.connect(func() -> void: _input_mouse_hovering = true)
	_pickable.mouse_exited.connect(func() -> void: _input_mouse_hovering = false)
	
	get_colliding_bodies()

func _input(event: InputEvent) -> void:
	if !read_input:
		return
	
	if _input_mouse_hovering && !_bubble_created:
		# TODO: Some indicator display.
		pass
	
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
	
	if read_input:
		if !_bubble_created:
			if _input_mouse_clicked:
				bubble_create()
			elif _input_mouse_hovering:
				pass# TODO: Bubble hover indicator.
		else:
			if _input_mouse_clicked:
				bubble_destroy()
			elif !_bubble_launched && !_input_mouse_clicking:
				bubble_launch(_input_mouse_vector * 128.0)
		_input_mouse_clicked = false
	
	if !_bubble_created:
		freeze = true
	else:
		freeze = false

#var _contact_colliders: Array[RID] = []
#var _contact_jiggle: float = 0.0

@export
var jiggle_acceleration_max: float = 2.0

## Exponential decay.
@export_range(0.001, 1.0, 0.001)
var jiggle_acceleration_decay: float = 1.0

var _jiggle_acceleration: float = 0.0

var _velocity_prev: Vector2 = Vector2.ZERO
func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if _bubble_created:
		# Workaround for contact impulse bug.
		_jiggle_acceleration += state.linear_velocity.distance_to(_velocity_prev)
		for contact: int in state.get_contact_count():
			var contact_layer: int = PhysicsServer2D.body_get_collision_layer(state.get_contact_collider(contact))
			if (contact_layer & (1 << 2)) > 0:
				bubble_destroy.call_deferred()
				break
	_velocity_prev = state.linear_velocity
	
	# Get jiggle strength from current frame contact impulses.
	#var contact_colliders: Array[RID] = []
	#for contact: int in state.get_contact_count():
		#print(state.get_contact_impulse(contact).length())
		#var collider: RID = state.get_contact_collider(contact)
		#contact_colliders.append(collider)
		#if !_contact_colliders.has(collider):
			#_contact_colliders.append(collider)
			#_contact_jiggle += state.get_contact_impulse(contact).length()
	
	# Remove colliders not detected this physics frame.
	#for contact_collider: RID in _contact_colliders:
		#if !contact_colliders.has(contact_collider):
			#_contact_colliders.erase(contact_collider)

@export
var apply_acceleration: bool = false:
	set(value):
		apply_acceleration = value
		_jiggle_acceleration = 128.0

@export_range(0.001, 16.0, 0.01)
var jiggle_period: float = 0.1

@export_range(0.0, 1.0, 0.001)
var jiggle_amplitude: float = 0.125

var _jiggle_time: float = 0.0

func _process(delta: float) -> void:
	_jiggle_acceleration = minf(_jiggle_acceleration, jiggle_acceleration_max)
	_jiggle_time = fmod(_jiggle_time + delta + minf(_jiggle_acceleration, jiggle_acceleration_max), jiggle_period)
	_jiggle_acceleration = maxf(_jiggle_acceleration * pow(1.0 - jiggle_acceleration_decay, delta), 0.0)
	var jiggle_seed: float = (_jiggle_time / jiggle_period) * TAU
	var jiggle: Vector2 = Vector2(absf(cos(jiggle_seed)), absf(sin(jiggle_seed)))
	jiggle = (jiggle * jiggle_amplitude) + Vector2(1.0 - jiggle_amplitude, 1.0 - jiggle_amplitude)
	_sprite.scale = jiggle
	
	if Engine.is_editor_hint():
		return
	queue_redraw()# Not optimal but works for now.

func _draw() -> void:
	if Engine.is_editor_hint():
		return
	# Later instead set an arrow texture visible when in State.BUBBLE_SETUP.
	if _bubble_created:
		draw_set_transform(Vector2.ZERO, Vector2.DOWN.angle_to(_input_mouse_vector))
		draw_line(Vector2.ZERO, Vector2.DOWN * 32.0, Color.RED, 2.0, false)
