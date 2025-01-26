@tool
extends Control
class_name MenuTitle

signal button_play_pressed()
signal button_credits_pressed()
signal button_quit_pressed()

@onready
var _button_play: Button = $buttons/button_play as Button
@onready
var _button_credits: Button = $buttons/button_credits as Button
@onready
var _button_quit: Button = $buttons/button_quit as Button

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	_button_play.pressed.connect(button_play_pressed.emit)
	_button_credits.pressed.connect(button_credits_pressed.emit)
	_button_quit.pressed.connect(button_quit_pressed.emit)

func set_interactive(interactive: bool) -> void:
	if interactive:
		_button_play.disabled = false
		_button_play.focus_mode = Control.FOCUS_ALL
		
		_button_credits.disabled = false
		_button_credits.focus_mode = Control.FOCUS_ALL
		
		_button_quit.disabled = false
		_button_quit.focus_mode = Control.FOCUS_ALL
		
		_button_play.grab_focus()
	else:
		_button_play.disabled = true
		_button_play.focus_mode = Control.FOCUS_NONE
		_button_play.release_focus()
		
		_button_credits.disabled = true
		_button_credits.focus_mode = Control.FOCUS_NONE
		_button_credits.release_focus()
		
		_button_quit.disabled = true
		_button_quit.focus_mode = Control.FOCUS_NONE
		_button_quit.release_focus()

func set_active(active: bool) -> void:
	if active:
		visible = true
	else:
		visible = false
