class_name ConfigFileSection
extends RefCounted


var _cfg: ConfigFile
var _section: String

var name: 
	get: return _section


func _init(section, cfg) -> void:
	self._cfg = cfg
	self._section = section


func get_value(key, default=null):
	return self._cfg.get_value(self._section, key, default)


func set_value(key, value):
	self._cfg.set_value(self._section, key, value)
