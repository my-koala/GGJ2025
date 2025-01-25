@tool
extends Control
class_name Dialogue

# TODO:
# - Animated opening and closing
# - Update graphic elements with art
# - Fix scaling problems

## Emitted when dialogue starts.
signal dialogue_started()

## Emitted when the current dialogue tree has finished.
signal dialogue_ended()

## Array of all dialogue entries
@export
var dialogue_entries: Array[DialogueEntry] = []

## Icon to display when a dialogue entry is finished.
@export
var finished_icon: Texture2D

## The person who is talking
@export
var agent: Texture2D

## Speed that characters talk, in characters per second
@export
var talking_speed: float = 5

## RichTextLabel which contains our dialogue
@export
var rich_text_label: RichTextLabel

# Internal signal that emits when the user presses a keyboard or mouse
signal _user_interacted()

func _ready() -> void:
	if Engine.is_editor_hint():
		return

	# Do not start any dialogue events if no entries are present	
	if dialogue_entries.size() == 0:
		return
	
	dialogue_started.emit()
	_play_dialogue()

# Emit our interaction signal if any keyboard or mouse press is detected
func _input(event: InputEvent) -> void:
	if (event is InputEventMouseButton or event is InputEventKey) and event.is_pressed():
		rich_text_label.visible_ratio = 1
		_user_interacted.emit()

# Iterates through all entries, awaits each one, and waits for player interaction before continuing
func _play_dialogue() -> void:
	for entry: DialogueEntry in dialogue_entries:
		var animatedTexture: AnimatedTexture = agent as AnimatedTexture
		
		if is_instance_valid(animatedTexture):
			animatedTexture.speed_scale = 1.0
		
		await _play_dialogue_entry(entry)
		
		if is_instance_valid(animatedTexture):
			animatedTexture.speed_scale = 0.0
			animatedTexture.current_frame = 0
		
		await _user_interacted
	
	dialogue_ended.emit()
	self.visible = false

# Scrolls one line of text, instantly finishing upon any user interaction
func _play_dialogue_entry(entry: DialogueEntry) -> void:
	var dialogue: String = entry.dialogue
	var currentCharacter: int = 0
	var characterDelay: float = 1 / talking_speed 
	
	rich_text_label.text = dialogue
	rich_text_label.visible_characters = 0
	
	while rich_text_label.visible_ratio < 1:
		rich_text_label.visible_characters += 1
		await get_tree().create_timer(characterDelay).timeout
	
	rich_text_label.append_text(" ")
	rich_text_label.add_image(finished_icon, 40)
	rich_text_label.visible_characters = -1
