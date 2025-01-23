@tool
extends Area2D
class_name Belt

## Velocity direction of conveyor belt.
@export
var direction: Vector2 = Vector2.ZERO:
	get:
		return direction
	set(value):
		direction = value.normalized()

## Speed of conveyor belt in pixels/second.
@export_range(0.0, 1.0, 1.0, "or_greater", "hide_slider")
var speed: float = 16.0:
	get:
		return speed
	set(value):
		speed = maxf(value, 0.0)

@onready
var _sprite: Sprite2D = $sprite_2d as Sprite2D
var _sprite_frame_delta: float = 0.0

var _items: Array[Item] = []

func get_velocity() -> Vector2:
	return direction * speed

func _on_body_entered(body: Node2D) -> void:
	var item: Item = body as Item
	if is_instance_valid(item):
		_items.append(item)
		

func _on_body_exited(body: Node2D) -> void:
	var item: Item = body as Item
	if is_instance_valid(item):
		_items.erase(item)

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	
	for item: Item in _items:
		item.apply_belt_velocity(get_velocity())

func _process(delta: float) -> void:
	# Sprite frame animation.
	if speed > 0.0:
		var sprite_frame_delta: float = 1.0 / speed
		_sprite_frame_delta += delta
		
		if _sprite_frame_delta > sprite_frame_delta:
			var advance: int = int(_sprite_frame_delta / sprite_frame_delta)
			_sprite_frame_delta = fmod(_sprite_frame_delta, sprite_frame_delta)
			_sprite.frame = (_sprite.frame + (2 * advance)) % _sprite.hframes
