class_name IConfigFileLike


func set_value(section: String, key: String, value: Variant) -> void:
	return utils.not_implemeted()


func get_value(section: String, key: String, default: Variant = null) -> Variant:
	return utils.not_implemeted()


func has_section_key(section: String, key: String) -> bool:
	return utils.not_implemeted()


func save(path: String) -> Error:
	return utils.not_implemeted()


static func of_config(cfg: ConfigFile) -> IConfigFileLike:
	return _OfConfig.new(cfg)


class _OfConfig extends IConfigFileLike:
	var _origin: ConfigFile
	
	func _init(origin: ConfigFile) -> void:
		_origin = origin
	
	func set_value(section: String, key: String, value: Variant) -> void:
		_origin.set_value(section, key, value)

	func get_value(section: String, key: String, default: Variant = null) -> Variant:
		return _origin.get_value(section, key, default)

	func save(path: String) -> Error:
		return _origin.save(path)

	func has_section_key(section: String, key: String) -> bool:
		return _origin.has_section_key(section, key)
