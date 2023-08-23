class_name ConfigFileValue 
extends RefCounted

var _cfg
var _section
var _key
var _backed_default


func _init(cfg, section, key, backed_default=null):
	_cfg = cfg
	_section = section
	_key = key
	_backed_default = backed_default


func ret(default=null):
	default = _backed_default if default == null else default
	return _cfg.get_value(_section, _key, default)


func put(value):
	_cfg.set_value(_section, _key, value)
