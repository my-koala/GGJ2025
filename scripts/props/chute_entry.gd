@tool
extends StaticBody2D
class_name ChuteEntry

# TODO:
# events for manager (e.g. item instantiated)
# also manager needs to know how many items are left to spawn (some sort of counter)

signal item_instantiated(item: Item)

## Item infos to instantiate item scenes from.
@export
var item_infos: Array[ItemInfo] = []

var _item_info_index: int = 0

## Time between item spawns.
@export
var spawn_frequency: float = 1.0

## Time before first item spawn.
@export
var spawn_delay: float = 1.0

@onready
var _thought: Thought = $thought as Thought

@onready
var _spawn_point: Marker2D = $spawn_point as Marker2D

var _spawn_time: float = 0.0

func get_items_left() -> int:
	return item_infos.size() - _item_info_index

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	_spawn_time = spawn_delay

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	
	if !item_infos.is_empty() && (_item_info_index < item_infos.size()):
		_thought.enabled = true
		_thought.set_display_texture(item_infos[_item_info_index].icon)
	else:
		_thought.enabled = false
		_thought.set_display_texture(null)
	
	_spawn_time -= delta
	
	if _item_info_index >= item_infos.size():
		return
	
	if _spawn_time < 0.0:
		_spawn_time = spawn_frequency
		# Spawn Item scene from ItemInfo.
		var item: Item = item_infos[_item_info_index].packed_scene.instantiate() as Item
		add_child(item)
		item.global_position = _spawn_point.global_position
		item.reset_physics_interpolation()
		_item_info_index += 1
		item_instantiated.emit(item)
