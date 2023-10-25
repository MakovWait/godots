class_name ConfigFileSection
extends RefCounted


var _cfg
var _section: String

var name: 
	get: return _section


func _init(section, cfg) -> void:
	self._cfg = cfg
	self._section = section


func get_value(key, default=null):
	return self._cfg.get_value(self._section, key, default)


func get_typed_value(key, type_check: Callable, default=null):
	if not _cfg.has_section_key(self._section, key):
		return default
	var value = self._cfg.get_value(self._section, key)
	if not type_check.call(value):
		return default
	return value


func set_value(key, value):
	self._cfg.set_value(self._section, key, value)
