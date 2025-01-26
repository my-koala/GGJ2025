@tool
extends Control
class_name MenuCredits

signal button_exit_pressed()

@onready
var _slide: Slide = $slide as Slide

@onready
var _button_exit: Button = $slide/panel/button_exit as Button

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	_button_exit.pressed.connect(button_exit_pressed.emit)

func set_interactive(interactive: bool) -> void:
	if interactive:
		_button_exit.disabled = false
		_button_exit.focus_mode = Control.FOCUS_ALL
		_button_exit.grab_focus()
	else:
		_button_exit.disabled = true
		_button_exit.focus_mode = Control.FOCUS_NONE
		_button_exit.release_focus()

func set_active(active: bool) -> void:
	if active:
		_slide.enabled = true
	else:
		_slide.enabled = false
