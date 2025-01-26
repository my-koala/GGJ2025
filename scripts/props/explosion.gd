@tool
extends Sprite2D
class_name Explosion

const EXPLOSION_TEXTURES_FOLDER: String = "res://assets/props/explosion/textures/"

var _explode: bool = false
func explode() -> void:
	_explode = true

var _explosion_textures: Array[Texture2D] = []
var _explosion_frame: int = 0
var _explosion_fps: float = 480.0
var _explosion_fps_delta: float = 0.0

func _init() -> void:
	if Engine.is_editor_hint():
		return
	
	var file_names: PackedStringArray = DirAccess.get_files_at(EXPLOSION_TEXTURES_FOLDER)
	for file_name: String in file_names:
		var explosion_texture: Texture2D = ResourceLoader.load(EXPLOSION_TEXTURES_FOLDER + file_name.replace(".import", "")) as Texture2D
		_explosion_textures.append(explosion_texture)
	

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	
	if !_explode:
		texture = null
		return
	
	var explode_fps_delta: float = 1.0 / _explosion_fps
	_explosion_fps_delta += delta
	while _explosion_fps_delta > explode_fps_delta:
		_explosion_fps_delta -= explode_fps_delta
		_explosion_frame += 1
		if _explosion_frame >= _explosion_textures.size():
			_explode = false
	
	if _explode:
		texture = _explosion_textures[_explosion_frame]
