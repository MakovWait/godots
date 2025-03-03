class_name ConfigFileSaveOnSet 
extends RefCounted

var _origin: IConfigFileLike
var _save_path_callback: Callable
var _save_callback: Callable


## save_callback: Optional[Callable]
func _init(cfg: IConfigFileLike, save_path: Variant, save_callback: Variant = null) -> void:
	_origin = cfg
	if save_path is Callable:
		_save_path_callback = save_path
	elif save_path is String:
		_save_path_callback = func() -> String: return save_path
	else:
		assert(false, "Incorrect save_path %s" % save_path)
	if save_callback is Callable:
		_save_callback = save_callback
	else:
		_save_callback = func(_err: Error) -> void: pass


func set_value(section: String, key: String, value: Variant) -> void:
	_origin.set_value(section, key, value)
	var err := _origin.save(_save_path_callback.call() as String)
	if _save_callback:
		_save_callback.call(err)


func get_value(section: String, key: String, default: Variant = null) -> Variant:
	return _origin.get_value(section, key, default)


func has_section_key(section: String, key: String) -> bool:
	return _origin.has_section_key(section, key)


func save(path: String) -> Error:
	return _origin.save(path)


func as_config_like() -> IConfigFileLike:
	return _AsConfigLike.new(self)


class _AsConfigLike extends IConfigFileLike:
	var _origin: ConfigFileSaveOnSet
	
	func _init(origin: ConfigFileSaveOnSet) -> void:
		_origin = origin
	
	func set_value(section: String, key: String, value: Variant) -> void:
		_origin.set_value(section, key, value)

	func get_value(section: String, key: String, default: Variant = null) -> Variant:
		return _origin.get_value(section, key, default)

	func has_section_key(section: String, key: String) -> bool:
		return _origin.has_section_key(section, key)

	func save(path: String) -> Error:
		return _origin.save(path)
