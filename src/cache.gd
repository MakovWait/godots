extends Node

const APP_CACHE_PATH = "user://.cache"

var _cache = ConfigFile.new()
var _cache_auto_save = ConfigFileSaveOnSet.new(_cache, APP_CACHE_PATH)


func _enter_tree():
	_cache.load(APP_CACHE_PATH)


func get_value(section: String, key: String, default: Variant = null):
	return _cache.get_value(section, key, default)


func set_value(section: String, key: String, value: Variant):
	_cache.set_value(section, key, value)


func save():
	return _cache.save(APP_CACHE_PATH)


func smart_value(scope, key: String, autosave=false) -> ConfigFileValue:
	var section = section_of(scope)
	assert(section != null)
	return ConfigFileValue.new(
		_cache_auto_save if autosave else _cache, 
		section, 
		key
	)


func smart_section(scope, autosave=false) -> ConfigFileSection:
	var section = section_of(scope)
	assert(section != null)
	return ConfigFileSection.new(
		section, 
		_cache_auto_save if autosave else _cache, 
	)


func section_of(obj):
	var section = null
	if obj is String:
		section = obj
	elif obj is Script:
		section = obj.resource_path
	elif obj.has_method("get_script"):
		section = obj.get_script().resource_path
	return section
