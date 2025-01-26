@tool
extends Resource
class_name LevelInfoDatabase

## Order of LevelInfos matter for displaying on level select!
@export
var level_infos: Array[LevelInfo] = []
