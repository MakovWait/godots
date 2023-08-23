class_name ConfigFileSaveOnSet 
extends RefCounted

var _origin: ConfigFile
var _save_path_callback: Callable
var _save_callback


func _init(cfg: ConfigFile, save_path, save_callback=null):
	_origin = cfg
	if save_path is Callable:
		_save_path_callback = save_path
	elif save_path is String:
		_save_path_callback = func(): return save_path
	else:
		assert(false, "Incorrect save_path %s" % save_path)
	_save_callback = save_callback


func set_value(section, key, value):
	_origin.set_value(section, key, value)
	var err = _origin.save(_save_path_callback.call())
	if _save_callback:
		_save_callback.call(err)


func get_value(section, key, default):
	return _origin.get_value(section, key, default)
