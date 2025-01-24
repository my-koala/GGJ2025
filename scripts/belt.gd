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

func get_velocity() -> Vector2:
	return direction * speed

func _process(delta: float) -> void:
	# Sprite frame animation.
	if speed > 0.0:
		var sprite_frame_delta: float = 1.0 / speed
		_sprite_frame_delta += delta
		
		if _sprite_frame_delta > sprite_frame_delta:
			var advance: int = int(_sprite_frame_delta / sprite_frame_delta)
			_sprite_frame_delta = fmod(_sprite_frame_delta, sprite_frame_delta)
			_sprite.frame = (_sprite.frame + (2 * advance)) % _sprite.hframes
