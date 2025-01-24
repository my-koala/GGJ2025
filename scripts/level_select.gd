@tool
extends Node
class_name LevelSelect

# TODO:
# - Store + retrieve a human readable name for each level
#   - Do we make a root Level node that stores the name?
#   - Do we store human names as another array in this script?
# - Actually do something with our _on_item_clicked event

@export
var level_list: ItemList

@export
var level_nodes: Array[PackedScene] = []

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	# Automatically populate our item list with levels
	for level: PackedScene in level_nodes:
		level_list.add_item(level.resource_name)
	
	level_list.item_clicked.connect(_on_item_clicked)

func _on_item_clicked(index: int) -> void:
	return
