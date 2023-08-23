class_name ConfigFileValue 
extends RefCounted

var _cfg
var _section
var _key
var _baked_default


func _init(cfg, section, key, baked_default=null):
	_cfg = cfg
	_section = section
	_key = key
	_baked_default = baked_default


func ret(default=null):
	default = _baked_default if default == null else default
	return _cfg.get_value(_section, _key, default)


func put(value):
	_cfg.set_value(_section, _key, value)


func put_custom(value, custom_cfg):
	custom_cfg.set_value(_section, _key, value)


func bake_default(default) -> ConfigFileValue:
	return ConfigFileValue.new(_cfg, _section, _key, default)
