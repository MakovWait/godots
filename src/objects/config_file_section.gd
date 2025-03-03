class_name ConfigFileSection
extends RefCounted


var _cfg: IConfigFileLike
var _section: String

var name: String: 
	get: return _section


func _init(section: String, cfg: IConfigFileLike) -> void:
	self._cfg = cfg
	self._section = section


func get_value(key: String, default: Variant = null) -> Variant:
	return self._cfg.get_value(self._section, key, default)


func get_typed_value(key: String, type_check: Callable, default: Variant = null) -> Variant:
	if not _cfg.has_section_key(self._section, key):
		return default
	var value: Variant = self._cfg.get_value(self._section, key)
	if not type_check.call(value):
		return default
	return value


func set_value(key: String, value: Variant) -> void:
	self._cfg.set_value(self._section, key, value)
