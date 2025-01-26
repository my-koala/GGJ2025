@tool
extends Area2D
class_name BubblePopper

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	var bubble: Bubble = body as Bubble
	if is_instance_valid(bubble)

func _on_body_exited(body: Node2D) -> void:
	pass
