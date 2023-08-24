class_name ConfigFileValue 
extends RefCounted

var _cfg
var _section
var _key
var _baked_default
var _map_return_value


func _init(cfg, section, key, baked_default=null):
	_cfg = cfg
	_section = section
	_key = key
	_baked_default = baked_default


func ret(default=null):
	default = _baked_default if default == null else default
	var value = _cfg.get_value(_section, _key, default) 
	if _map_return_value:
		value = _map_return_value.call(value)
	return value


func put(value):
	_cfg.set_value(_section, _key, value)


func put_custom(value, custom_cfg):
	custom_cfg.set_value(_section, _key, value)


func bake_default(default) -> ConfigFileValue:
	return ConfigFileValue.new(_cfg, _section, _key, default)


func map_return_value(callback) -> ConfigFileValue:
	var result = ConfigFileValue.new(_cfg, _section, _key, _baked_default)
	result._map_return_value = callback
	return result


func get_baked_default():
	return _baked_default
