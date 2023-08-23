class_name ConfigFileSaveOnSet 
extends RefCounted

var _origin: ConfigFile
var _save_path_callback: Callable


func _init(cfg: ConfigFile, save_path):
	_origin = cfg
	if save_path is Callable:
		_save_path_callback = save_path
	elif save_path is String:
		_save_path_callback = func(): return save_path
	else:
		assert(false, "Incorrect save_path %s" % save_path)


func set_value(section, key, value):
	_origin.set_value(section, key, value)
	_origin.save(_save_path_callback.call())


func get_value(section, key, default):
	return _origin.get_value(section, key, default)
