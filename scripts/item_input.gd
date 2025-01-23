@tool
extends Node2D
class_name ItemInput

# TODO:
# events for manager (e.g. item instantiated)
# also manager needs to know how many items are left to spawn (some sort of counter)

signal item_instantiated(item: Item)

@export
var spawn_root: NodePath = NodePath("..")

# spawn items
@export
var items: Array[PackedScene] = []

var _item_index: int = 0

## Time between item spawns.
@export
var spawn_frequency: float = 1.0

## Time before first item spawn.
@export
var spawn_delay: float = 1.0

var _spawn_time: float = 0.0

func get_items_left() -> int:
	return items.size() - _item_index

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	_spawn_time = spawn_delay

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_spawn_time -= delta
	
	if _item_index >= items.size():
		return
	
	if _spawn_time < 0.0:
		_spawn_time = spawn_frequency
		# spawn item
		var item: Item = items[_item_index].instantiate() as Item
		get_node(spawn_root).add_child(item)
		item.global_position = global_position
		item.reset_physics_interpolation()
		_item_index += 1
		item_instantiated.emit(item)
