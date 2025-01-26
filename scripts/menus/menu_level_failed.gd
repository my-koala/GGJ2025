@tool
extends Control
class_name MenuLevelFailed

signal button_retry_pressed()
signal button_exit_pressed()

@onready
var _slide: Slide = $slide as Slide

@onready
var _button_retry: Button = $slide/panel/button_retry as Button
@onready
var _button_exit: Button = $slide/panel/button_exit as Button

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	_button_retry.pressed.connect(button_retry_pressed.emit)
	_button_exit.pressed.connect(button_exit_pressed.emit)
	
	set_active(false)

func set_interactive(interactive: bool) -> void:
	if interactive:
		_button_retry.disabled = false
		_button_retry.focus_mode = Control.FOCUS_ALL
		_button_retry.grab_focus()
		
		_button_exit.disabled = false
		_button_exit.focus_mode = Control.FOCUS_ALL
	else:
		_button_retry.disabled = true
		_button_retry.focus_mode = Control.FOCUS_NONE
		_button_retry.release_focus()
		
		_button_exit.disabled = true
		_button_exit.focus_mode = Control.FOCUS_NONE
		_button_exit.release_focus()

func set_active(active: bool) -> void:
	if active:
		_slide.enabled = true
	else:
		_slide.enabled = false
