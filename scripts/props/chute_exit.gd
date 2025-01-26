@tool
extends StaticBody2D
class_name ChuteExit

signal item_destroyed(item: Item, correct: bool)

## Item infos to test detected items against (in sequential order).
@export
var item_infos: Array[ItemInfo] = []

@onready
var _item_detect: Area2D = $item_detect as Area2D
@onready
var _item_detect_collision_shape: CollisionShape2D = $item_detect/collision_shape_2d as CollisionShape2D
@onready
var _thought: Thought = $thought as Thought

@export
var item_center_check: bool = false

var _items_collided: Array[Item] = []

var _item_info_index: int = 0

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	_item_detect.body_entered.connect(_on_body_entered)

func _on_body_entered(node: Node2D) -> void:
	var item: Item = node as Item
	if is_instance_valid(item):
		_items_collided.append(item)

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	
	if !item_infos.is_empty():
		_thought.enabled = true
		_thought.set_display_texture(item_infos[_item_info_index].icon)
	else:
		_thought.enabled = false
		_thought.set_display_texture(null)
	
	for item: Item in _items_collided:
		if !item.is_bubble():
			var rect: Rect2 = _item_detect_collision_shape.shape.get_rect()
			if !item_center_check || rect.has_point(item.global_position - global_position):
				_destroy_item(item)
				_items_collided.erase(item)

func _destroy_item(item: Item) -> void:
	var correct: bool = false
	if !item_infos.is_empty() && item_infos[_item_info_index].identifier == item.identifier:
		_item_info_index = (_item_info_index + 1) % item_infos.size()
		correct = true
	item_destroyed.emit(item, correct)
	item.queue_free()
