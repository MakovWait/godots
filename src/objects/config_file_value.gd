class_name ConfigFileValue 
extends RefCounted

var _cfg: IConfigFileLike
var _section: String
var _key: String
var _baked_default: Variant
var _map_return_value: Callable


func _init(cfg: IConfigFileLike, section: String, key: String, baked_default: Variant = null) -> void:
	_cfg = cfg
	_section = section
	_key = key
	_baked_default = baked_default


func exists() -> bool:
	return _cfg.has_section_key(_section, _key)


func ret(default: Variant = null) -> Variant:
	default = _baked_default if default == null else default
	var value: Variant = _cfg.get_value(_section, _key, default) 
	if _map_return_value:
		value = _map_return_value.call(value)
	return value


func put(value: Variant) -> void:
	_cfg.set_value(_section, _key, value)


func put_custom(value: Variant, custom_cfg: IConfigFileLike) -> void:
	custom_cfg.set_value(_section, _key, value)


func bake_default(default: Variant) -> ConfigFileValue:
	return ConfigFileValue.new(
		_cfg, _section, _key, default
	).map_return_value(_map_return_value)


func map_return_value(callback: Callable) -> ConfigFileValue:
	var result := ConfigFileValue.new(_cfg, _section, _key, _baked_default)
	result._map_return_value = callback
	return result


func get_baked_default() -> Variant:
	return _baked_default
