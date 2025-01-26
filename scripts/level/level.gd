@tool
extends Node
class_name Level

signal ended(passed: bool)

@onready
var _chutes: Node2D = $chutes as Node2D

@onready
var _dialogue: Dialogue = $canvas_layer/dialogue_system as Dialogue

@onready
var _camera: Camera2D = $camera_2d as Camera2D

var played: bool = false# used for dialogue check

var _chute_entries: Array[ChuteEntry] = []
var _chute_exits: Array[ChuteExit] = []

var _total_items: int = 0
var _items_destroyed: int = 0

# Call when the level is considered a success
func _pass_level() -> void:
	ended.emit(true)

var _level_failed: bool = false
# Call when the level is considered failed
func _fail_level() -> void:
	if _level_failed:
		return
	_level_failed = true
	ended.emit(false)

@export
var camera_shake_strength: float = 8.0
@export_range(0.001, 1.0, 0.001)
var camera_shake_decay: float = 0.95
var _camera_shake: float = 0.0

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_camera.make_current()
	for node: Node in _chutes.get_children():
		var chute_entry: ChuteEntry = node as ChuteEntry
		if is_instance_valid(chute_entry):
			chute_entry.item_instantiated.connect(_on_item_instantiated)
			_total_items += chute_entry.item_infos.size()
			_chute_entries.append(chute_entry)
		
		var chute_exit: ChuteExit = node as ChuteExit
		if is_instance_valid(chute_exit):
			chute_exit.item_destroyed.connect(_on_item_destroyed)
			_chute_exits.append(chute_exit)
	
	# If dialogue is present, start chutes once the dialogue is finished
	# Instantly start chutes otherwise
	if is_instance_valid(_dialogue):
		if !played:
			_dialogue.dialogue_ended.connect(_on_dialog_finished)
			_dialogue.play_dialogue()
		else:
			_on_dialog_finished()
	else:
		print("no dialogue???")
		_on_dialog_finished()

func _on_dialog_finished() -> void:
	for chute_entry: ChuteEntry in _chute_entries:
		chute_entry.start()

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	
	_camera_shake = _camera_shake * pow(1.0 - camera_shake_decay, delta)
	_camera.offset = Vector2(randf(), randf()) * minf(_camera_shake, camera_shake_strength)

# When an item is instantiated by an Item Input, we need the manager to listen
# to when that item is dropped on the floor. This can be a fail state.
func _on_item_instantiated(item: Item) -> void:
	item.item_dropped.connect(_on_item_dropped)

@export
var item_dropped_wait: float = 1.0
var _item_dropped_wait: float = 0.0
var _item_dropped: bool = false

# When an item has fallen, it is a fail state
# We disconnect the item drop event as well just for safety
#  (Also to ensure we aren't spammed drop events every frame, hehe)
func _on_item_dropped() -> void:
	_camera_shake = 32.0
	_item_dropped = true
	_item_dropped_wait = item_dropped_wait

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	
	if _item_dropped:
		if _item_dropped_wait > 0.0:
			_item_dropped_wait -= delta
		else:
			_fail_level()

func _on_item_destroyed(item: Item, correct: bool) -> void:
	# Fail state if the destroyed item isn't correct as reported by the output
	if !correct:
		_fail_level()
		return
	
	# Increment our internal counter
	# Win state is when the items we destroy equals the total number of items from all inputs
	_items_destroyed += 1
	if _items_destroyed == _total_items:
		_pass_level()
