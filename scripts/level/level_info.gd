@tool
extends Resource
class_name LevelInfo

# TODO: could do some persist data to load completion status

@export
var packed_scene: PackedScene = null

@export
var name: StringName = &""

@export
var difficulty: int = 0# idea: 1-5 star difficult rating

var completed: bool = false
