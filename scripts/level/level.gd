@tool
extends Node
class_name Level

signal ended(passed: bool)

@onready
var _chutes: Node2D = $chutes as Node2D

var _chute_entries: Array[ChuteEntry] = []
var _chute_exits: Array[ChuteExit] = []

var _total_items: int = 0
var _items_destroyed: int = 0

# Call when the level is considered a success
func _pass_level() -> void:
	ended.emit(true)

# Call when the level is considered failed
func _fail_level() -> void:
	ended.emit(false)

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
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

# When an item is instantiated by an Item Input, we need the manager to listen
# to when that item is dropped on the floor. This can be a fail state.
func _on_item_instantiated(item: Item) -> void:
	item.item_dropped.connect(_on_item_dropped)

# When an item has fallen, it is a fail state
# We disconnect the item drop event as well just for safety
#  (Also to ensure we aren't spammed drop events every frame, hehe)
func _on_item_dropped() -> void:
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
