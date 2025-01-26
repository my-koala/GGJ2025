@tool
extends Node2D
class_name Thought

@export
var enabled: bool = true

@export
var anchor_offset: Vector2 = Vector2.ONE * 32.0

@export
var display_size: Vector2 = Vector2(64.0, 64.0)

@onready
var body: Sprite2D = $body as Sprite2D

@onready
var a: Sprite2D = $a as Sprite2D

@onready
var b: Sprite2D = $b as Sprite2D

@onready
var display: Sprite2D = $body/display as Sprite2D

@export_range(0.0, 32.0, 0.001)
var bob_amplitude: float = 4.0
@export_range(0.001, 16.0, 0.001)
var bob_period: float = 3.0

var _bob_time: float = 0.0

@export
var opening_time: float = 0.5
var _opening_time: float = 0.0

@export
var closing_time: float = 0.25
var _closing_time: float = 0.0

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	if enabled:
		_opening_time = opening_time
	else:
		_closing_time = closing_time

func _physics_process(delta: float) -> void:
	if enabled:
		if _opening_time < opening_time:
			_opening_time = minf(_opening_time + delta, opening_time)
			var weight: float = clampf(_opening_time / opening_time, 0.0, 1.0)
			body.modulate.a = clampf(remap(weight, 0.5, 1.0, 0.0, 1.0), 0.0, 1.0)
			a.modulate.a = clampf(remap(weight, 0.25, 0.75, 0.0, 1.0), 0.0, 1.0)
			b.modulate.a = clampf(remap(weight, 0.0, 0.5, 0.0, 1.0), 0.0, 1.0)
		_closing_time = (1.0 - (_opening_time / opening_time)) * closing_time
	else:
		if _closing_time < closing_time:
			_closing_time = minf(_closing_time + delta, closing_time)
			var weight: float = clampf(_closing_time / closing_time, 0.0, 1.0)
			body.modulate.a = clampf(remap(weight, 0.5, 1.0, 1.0, 0.0), 0.0, 1.0)
			a.modulate.a = clampf(remap(weight, 0.25, 0.75, 1.0, 0.0), 0.0, 1.0)
			b.modulate.a = clampf(remap(weight, 0.0, 0.5, 1.0, 0.0), 0.0, 1.0)
		_opening_time = (1.0 - (_closing_time / closing_time)) * opening_time

func set_display_texture(texture: Texture2D) -> void:
	if display.texture == texture:
		return
	display.texture = texture
	if is_instance_valid(texture):
		# Scale to fit 64.0x64.0
		display.scale = display_size / texture.get_size()

func _process(delta: float) -> void:
	_bob_time = fmod(_bob_time + delta, bob_period)
	var bob: float = sin((_bob_time / bob_period) * TAU)
	body.position.y = bob * bob_amplitude
	
	a.position = anchor_offset * 0.5
	a.offset.y = bob * bob_amplitude * -0.5
	
	b.position = anchor_offset * 0.75
	b.offset.y = bob * bob_amplitude * 0.25
