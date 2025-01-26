@tool
extends Area2D
class_name ChuteExit

signal item_destroyed(item: Item, correct: bool)

@export
var items_expected: Array[StringName] = []

var _items_collided: Array[Item] = []

var _item_expected: int = 0

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	body_entered.connect(_on_body_entered)

func _on_body_entered(node: Node2D) -> void:
	var item: Item = node as Item
	if is_instance_valid(item):
		if item.is_bubble():
			_items_collided.append(item)
			return
		_destroy_item(item)

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	
	for item: Item in _items_collided:
		if !item.is_bubble():
			_destroy_item(item)
			_items_collided.erase(item)

func _destroy_item(item: Item) -> void:
	var correct: bool = items_expected[_item_expected] == item.identifier
	if correct:
		_item_expected = (_item_expected + 1) % items_expected.size()
	item_destroyed.emit(item, correct)
	item.queue_free()
