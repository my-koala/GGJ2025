@tool
extends Node
class_name Main

# TODO:
# Add credits screen
# Add options menu, with level context buttons
# - opens sub menu in top right
# - can have buttons to restart level (if in level)

const LEVEL_INFO_DATABASE: LevelInfoDatabase = preload("res://assets/levels/level_info_database.tres")

enum State {
	NONE,
	PRECOMPILE,
	TRANSITION,
	PLAY,
	HOME,
	OPTIONS,
}
var _state: State = State.NONE

enum MenuState {
	NONE,
	TITLE,
	LEVEL_SELECT,
	LEVEL_PASSED,
	LEVEL_FAILED,
	CREDITS,
}
var _menu_state: MenuState = MenuState.NONE

## Root node to add levels to.
@onready
var _play: Node2D = $world/play as Node2D

@onready
var _screen_transition: TextureRect = $screen/transition as TextureRect
@onready
var _screen_transition_sfx: AudioStreamPlayer = $screen/transition/transition_sfx as AudioStreamPlayer
@onready
var _screen_loading: Control = $screen/loading as Control

@onready
var _menu_overlay: Overlay = $menus/overlay as Overlay

@onready
var _menu_title: MenuTitle = $menus/menu_title as MenuTitle
@onready
var _menu_level_select: MenuLevelSelect = $menus/menu_level_select as MenuLevelSelect
@onready
var _menu_level_passed: MenuLevelPassed = $menus/menu_level_passed as MenuLevelPassed
@onready
var _menu_level_failed: MenuLevelFailed = $menus/menu_level_failed as MenuLevelFailed
@onready
var _menu_credits: MenuCredits = $menus/menu_credits as MenuCredits

# need to load next level on middle of transition though...
var _level_info: LevelInfo = null
var _level_instance: Level = null# currently instanced level

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	# TODO: Await shader precompile.
	_set_state.call_deferred(State.HOME)
	
	_screen_transition.position.y = _screen_transition.size.y / 2.0
	
	# TODO: credits, quit??
	
	_menu_title.button_play_pressed.connect(_set_menu_state.bind(MenuState.LEVEL_SELECT))
	_menu_title.button_credits_pressed.connect(_set_menu_state.bind(MenuState.CREDITS))
	
	_menu_level_select.button_level_pressed.connect(_load_level)
	_menu_level_select.button_exit_pressed.connect(_set_menu_state.bind(MenuState.TITLE))
	
	_menu_level_passed.button_next_pressed.connect(_load_next_level)
	_menu_level_passed.button_exit_pressed.connect(_quit_to_title)
	
	_menu_level_failed.button_retry_pressed.connect(_reload_level)
	_menu_level_failed.button_exit_pressed.connect(_quit_to_title)
	
	_menu_credits.button_exit_pressed.connect(_set_menu_state.bind(MenuState.TITLE))

func _load_level(level_info: LevelInfo) -> void:
	_set_state(State.TRANSITION)
	
	var level_instance: Level = await _load_level_instance(level_info)
	
	await _play_transition()
	
	if is_instance_valid(_level_instance):
		_level_instance.ended.disconnect(_on_level_ended)
		_level_instance.queue_free()
	
	_level_info = level_info
	_level_instance = level_instance
	
	if is_instance_valid(_level_instance):
		_level_instance.ended.connect(_on_level_ended)
		_level_instance.played = _level_info.played
		_level_info.played = true
		_play.add_child(_level_instance)
	
	_set_state(State.PLAY)

func _load_next_level() -> void:
	_set_state(State.TRANSITION)
	
	var level_info: LevelInfo = _get_next_level(_level_info)
	var level_instance: Level = await _load_level_instance(level_info)
	
	await _play_transition()
	
	if is_instance_valid(_level_instance):
		_level_instance.ended.disconnect(_on_level_ended)
		_level_instance.queue_free()
	
	_level_info = level_info
	_level_instance = level_instance
	
	if is_instance_valid(_level_instance):
		_level_instance.ended.connect(_on_level_ended)
		_level_instance.played = _level_info.played
		_level_info.played = true
		_play.add_child(_level_instance)
	
	_set_state(State.PLAY)

func _reload_level() -> void:
	_set_state(State.TRANSITION)
	
	var level_instance: Level = await _load_level_instance(_level_info)
	
	await _play_transition()
	
	if is_instance_valid(_level_instance):
		_level_instance.ended.disconnect(_on_level_ended)
		_level_instance.queue_free()
	
	_level_instance = level_instance
	
	if is_instance_valid(_level_instance):
		_level_instance.ended.connect(_on_level_ended)
		_level_instance.played = _level_info.played
		_level_info.played = true
		_play.add_child(_level_instance)
	
	_set_state(State.PLAY)

func _quit_to_title() -> void:
	_set_state(State.TRANSITION)
	
	await _play_transition()
	
	_unload_level_instance()
	
	_set_state(State.HOME)

func _get_next_level(level_info: LevelInfo) -> LevelInfo:
	var index: int = LEVEL_INFO_DATABASE.level_infos.find(level_info)
	if index == -1:
		return null
	if index == LEVEL_INFO_DATABASE.level_infos.size() - 1:
		return null
	return LEVEL_INFO_DATABASE.level_infos.get(index + 1) as LevelInfo

func _play_transition() -> void:
	var tween: Tween = create_tween()
	tween.set_process_mode(Tween.TWEEN_PROCESS_IDLE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.set_parallel(false)
	
	var start: float = _screen_transition.size.y / 2.0
	var end: float = -_screen_transition.size.y
	var halfway: float = (start + end) / 2.0
	_screen_transition.position.y = start
	tween.tween_property(_screen_transition, "position:y", halfway, 0.25)
	tween.tween_property(_screen_transition, "position:y", end, 0.25)
	
	_screen_transition_sfx.play()
	
	await tween.step_finished

# TODO: Make asynchronous load.
var _loading_level_instance: bool = false
func _load_level_instance(level_info: LevelInfo) -> Level:
	if _loading_level_instance:
		push_error("Tried to request a level when already requesting!")
		return
	_loading_level_instance = true
	
	# Load level instance.
	var level_instance: Level = null
	
	if is_instance_valid(level_info):
		# le fake the loading (for now)
		#await get_tree().create_timer(1.0).timeout
		var scene_path: String = level_info.packed_scene.resource_path
		ResourceLoader.load_threaded_request(scene_path)
		while ResourceLoader.load_threaded_get_status(scene_path) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			await get_tree().physics_frame
		var level_packed_scene: PackedScene = ResourceLoader.load_threaded_get(scene_path) as PackedScene
		if is_instance_valid(level_packed_scene):
			level_instance = level_packed_scene.instantiate() as Level
		else:
			push_error("failed to load the level thign bro")
	
	_loading_level_instance = false
	return level_instance

func _unload_level_instance() -> void:
	_level_instance.queue_free()
	_level_instance = null
	_level_info = null

func _on_level_ended(passed: bool) -> void:
	if passed:
		_level_info.completed = true
		_set_menu_state(MenuState.LEVEL_PASSED)
	else:
		_set_menu_state(MenuState.LEVEL_FAILED)

# TODO: transitions
# TODO: play needs
func _set_state(state: State) -> void:
	if _state == state:
		return
	_state = state
	
	match _state:
		State.NONE:
			pass
		State.PRECOMPILE:
			pass# TODO: precompile shaders
		State.TRANSITION:
			_menu_title.set_interactive(false)
			_menu_level_select.set_interactive(false)
			_menu_level_passed.set_interactive(false)
			_menu_level_failed.set_interactive(false)
			
			_screen_loading.visible = true
			_screen_loading.mouse_filter = Control.MOUSE_FILTER_STOP
		State.HOME:
			_set_menu_state(MenuState.TITLE)
			_play.visible = false
			
			_screen_loading.visible = false
			_screen_loading.mouse_filter = Control.MOUSE_FILTER_IGNORE
		State.PLAY:
			_set_menu_state(MenuState.NONE)
			_play.visible = true
			
			_screen_loading.visible = false
			_screen_loading.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _set_menu_state(menu_state: MenuState) -> void:
	if _menu_state == menu_state:
		return
	_menu_state = menu_state
	
	match _menu_state:
		MenuState.NONE:
			_menu_overlay.enabled = false
			
			_menu_title.set_active(false)
			_menu_title.set_interactive(false)
			
			_menu_level_select.set_active(false)
			_menu_level_select.set_interactive(false)
			
			_menu_level_passed.set_active(false)
			_menu_level_passed.set_interactive(false)
			
			_menu_level_failed.set_active(false)
			_menu_level_failed.set_interactive(false)
			
			_menu_credits.set_active(false)
			_menu_credits.set_interactive(false)
		MenuState.TITLE:
			_menu_overlay.enabled = false
			
			_menu_title.set_active(true)
			_menu_title.set_interactive(true)
			
			_menu_level_select.set_active(false)
			_menu_level_select.set_interactive(false)
			
			_menu_level_passed.set_active(false)
			_menu_level_passed.set_interactive(false)
			
			_menu_level_failed.set_active(false)
			_menu_level_failed.set_interactive(false)
			
			_menu_credits.set_active(false)
			_menu_credits.set_interactive(false)
		MenuState.LEVEL_SELECT:
			_menu_overlay.enabled = true
			
			_menu_title.set_active(false)
			_menu_title.set_interactive(false)
			
			_menu_level_select.set_active(true)
			_menu_level_select.set_interactive(true)
			
			_menu_level_passed.set_active(false)
			_menu_level_passed.set_interactive(false)
			
			_menu_level_failed.set_active(false)
			_menu_level_failed.set_interactive(false)
			
			_menu_credits.set_active(false)
			_menu_credits.set_interactive(false)
		MenuState.LEVEL_PASSED:
			_menu_overlay.enabled = true
			
			_menu_title.set_active(false)
			_menu_title.set_interactive(false)
			
			_menu_level_select.set_active(false)
			_menu_level_select.set_interactive(false)
			
			_menu_level_passed.set_active(true)
			_menu_level_passed.set_interactive(true)
			
			_menu_level_failed.set_active(false)
			_menu_level_failed.set_interactive(false)
			
			_menu_credits.set_active(false)
			_menu_credits.set_interactive(false)
		MenuState.LEVEL_FAILED:
			_menu_overlay.enabled = true
			
			_menu_title.set_active(false)
			_menu_title.set_interactive(false)
			
			_menu_level_select.set_active(false)
			_menu_level_select.set_interactive(false)
			
			_menu_level_passed.set_active(false)
			_menu_level_passed.set_interactive(false)
			
			_menu_level_failed.set_active(true)
			_menu_level_failed.set_interactive(true)
			
			_menu_credits.set_active(false)
			_menu_credits.set_interactive(false)
		MenuState.CREDITS:
			_menu_overlay.enabled = true
			
			_menu_title.set_active(false)
			_menu_title.set_interactive(false)
			
			_menu_level_select.set_active(false)
			_menu_level_select.set_interactive(false)
			
			_menu_level_passed.set_active(false)
			_menu_level_passed.set_interactive(false)
			
			_menu_level_failed.set_active(false)
			_menu_level_failed.set_interactive(false)
			
			_menu_credits.set_active(true)
			_menu_credits.set_interactive(true)
