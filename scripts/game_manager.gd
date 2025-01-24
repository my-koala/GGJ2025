@tool
extends Node2D
class_name GameManager

## Emitted when the level has reached a passing state (we win!)
signal on_level_pass()

## Emitted when the level has reached a failing state (an item was dropped or the wrong item was in an output) 
signal on_level_fail()

## All item inputs/spawners in the level
@export
var itemInputs: Array[ItemInput] = []

## All item outputs/chutes in the level
@export
var itemOutputs: Array[ItemOutput] = []

var _total_items: int = 0
var _items_destroyed: int = 0

# Call when the level is considered a success
func _pass_level() -> void:
	print("level won!")
	on_level_pass.emit()

# Call when the level is considered failed
func _fail_level() -> void:
	print("level failed")
	on_level_fail.emit()

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	for input: ItemInput in itemInputs:
		input.item_instantiated.connect(_on_item_instantiated)
		_total_items += input.items.size()
		
	for output: ItemOutput in itemOutputs:
		output.item_destroyed.connect(_on_item_destroyed)

# In Unity, I am used to unsubscribing from all events in OnDestroy() for safety
# This seems to be the equivalent in Godot, although I'm unsure how necessary this is
func _exit_tree() -> void:
	if Engine.is_editor_hint():
		return
	
	for input: ItemInput in itemInputs:
		input.item_instantiated.disconnect(_on_item_instantiated)
	
	for output: ItemOutput in itemOutputs:
		output.item_destroyed.disconnect(_on_item_destroyed)

# When an item is instantiated by an Item Input, we need the manager to listen
# to when that item is dropped on the floor. This can be a fail state.
func _on_item_instantiated(item: Item) -> void:
	item.item_dropped.connect(_on_item_dropped)

# When an item has fallen, it is a fail state
# We disconnect the item drop event as well just for safety
#  (Also to ensure we aren't spammed drop events every frame, hehe)
func _on_item_dropped(item: Item) -> void:
	item.item_dropped.disconnect(_on_item_dropped)
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
