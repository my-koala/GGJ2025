@tool
extends Control
class_name MenuLevelSelect

signal button_level_pressed(level_info: LevelInfo)
signal button_exit_pressed()

## Database that tracks LevelInfos.
@export
var level_info_database: LevelInfoDatabase = null

## Button to add to level select container.
@export
var level_button_scene: PackedScene = null

@onready
var _slide: Slide = $slide as Slide

@onready
var _flow_container: FlowContainer = $slide/panel/flow_container as FlowContainer

@onready
var _button_exit: Button = $slide/panel/button_exit as Button

var _level_buttons: Array[Button] = []

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	_button_exit.pressed.connect(button_exit_pressed.emit)
	
	var level_index: int = 1
	for level_info: LevelInfo in level_info_database.level_infos:
		var level_button: Button = level_button_scene.instantiate() as Button
		level_button.pressed.connect(_on_level_button_pressed.bind(level_info))
		level_button.text = str(level_index)
		_flow_container.add_child(level_button)
		_level_buttons.append(level_button)
		level_index += 1

func _on_level_button_pressed(level_info: LevelInfo) -> void:
	button_level_pressed.emit(level_info)

func set_interactive(interactive: bool) -> void:
	if interactive:
		_button_exit.disabled = false
		_button_exit.focus_mode = Control.FOCUS_ALL
		
		for level_button: Button in _level_buttons:
			level_button.disabled = false
			level_button.focus_mode = Control.FOCUS_ALL
		
		if !_level_buttons.is_empty():
			_level_buttons[0].grab_focus()
		else:
			_button_exit.grab_focus()
	else:
		_button_exit.disabled = true
		_button_exit.focus_mode = Control.FOCUS_NONE
		
		for level_button: Button in _level_buttons:
			level_button.disabled = true
			level_button.focus_mode = Control.FOCUS_NONE
			level_button.release_focus()

func set_active(active: bool) -> void:
	if active:
		_slide.enabled = true
	else:
		_slide.enabled = false
