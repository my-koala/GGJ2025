@tool
extends Node
class_name LevelSelect

# TODO:
# display level name when button is hovered over
# 


signal level_selected(level_info: LevelInfo)

## Database that tracks LevelInfos.
@export
var level_info_database: LevelInfoDatabase = null

## Button to add to level select container.
@export
var button_scene: PackedScene = null

@onready
var _flow_container: FlowContainer = $panel/flow_container as FlowContainer

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	for level_info: LevelInfo in level_info_database.level_infos:
		var level_button: Button = button_scene.instantiate() as Button
		level_button.pressed.connect(_on_level_button_pressed.bind(level_info))
		_flow_container.add_child(level_button)

func _on_level_button_pressed(level_info: LevelInfo) -> void:
	print("button pressed: " + str(level_info.name))
	level_selected.emit(level_info)
