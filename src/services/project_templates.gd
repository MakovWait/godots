class_name ProjectTemplates

const _dict = preload("res://src/extensions/dict.gd")

class List extends RefCounted:
	var _cfg := ConfigFile.new()
	var _templates: Dictionary[String, Item] = {}
	var _cfg_path: String
	var _templates_dir: String
	
	func _init(cfg_path: String, templates_dir: String) -> void:
		_cfg_path = cfg_path
		_templates_dir = templates_dir
	
	func add(name: String, description: String, source_project_path: String, tags: Array = []) -> Item:
		var id := _generate_id()
		var section := "template_%s" % id
		var template_zip_path := _templates_dir.path_join("%s.zip" % id)
		
		var item := Item.new(
			section,
			ConfigFileSection.new(section, IConfigFileLike.of_config(_cfg)),
			template_zip_path
		)
		item.name = name
		item.description = description
		item.source_project_path = source_project_path
		item.tags = tags
		item.created_at = int(Time.get_unix_time_from_system())
		_templates[id] = item
		return item
	
	func all() -> Array[Item]:
		var result: Array[Item] = []
		for x: Item in _templates.values():
			result.append(x)
		return result
	
	func retrieve(id: String) -> Item:
		return _templates.get(id, null)
	
	func has(id: String) -> bool:
		return _templates.has(id)
	
	func erase(id: String) -> void:
		var item := _templates.get(id, null)
		if item:
			# Delete the zip file
			if FileAccess.file_exists(item.zip_path):
				DirAccess.remove_absolute(item.zip_path)
		_templates.erase(id)
		_cfg.erase_section("template_%s" % id)
	
	# TODO type
	func get_all_tags() -> Array:
		var set := Set.new()
		for template: Item in _templates.values():
			for tag: String in template.tags:
				set.append(tag.to_lower())
		return set.values()
	
	func load() -> Error:
		cleanup()
		DirAccess.make_dir_recursive_absolute(_templates_dir)
		var err := _cfg.load(_cfg_path)
		if err and err != ERR_FILE_NOT_FOUND:
			return err
		for section in _cfg.get_sections():
			if section.begins_with("template_"):
				var id := section.substr("template_".length())
				_templates[id] = Item.new(
					section,
					ConfigFileSection.new(section, IConfigFileLike.of_config(_cfg)),
					_templates_dir.path_join("%s.zip" % id)
				)
		return Error.OK
	
	func cleanup() -> void:
		_dict.clear_and_free(_templates)
	
	func save() -> Error:
		return _cfg.save(_cfg_path)
	
	func _generate_id() -> String:
		return str(int(Time.get_unix_time_from_system() * 1000)) + "_" + str(randi() % 10000)


class Item:
	signal internals_changed
	signal loaded
	
	var id: String:
		get: return _section.name.substr("template_".length())
	
	var name: String:
		get: return _section.get_value("name", "Unnamed Template")
		set(value): _section.set_value("name", value)
	
	var description: String:
		get: return _section.get_value("description", "")
		set(value): _section.set_value("description", value)
	
	var source_project_path: String:
		get: return _section.get_value("source_project_path", "")
		set(value): _section.set_value("source_project_path", value)
	
	var zip_path: String:
		get: return _zip_path
	
	var tags: Array:
		get: return _section.get_value("tags", [])
		set(value): _section.set_value("tags", value)
	
	var created_at: int:
		get: return _section.get_value("created_at", 0)
		set(value): _section.set_value("created_at", value)
	
	var is_zip_valid: bool:
		get: return FileAccess.file_exists(_zip_path)
	
	var _section: ConfigFileSection
	var _zip_path: String
	
	func _init(section_name: String, section: ConfigFileSection, zip_path: String) -> void:
		_section = section
		_zip_path = zip_path
	
	func get_formatted_date() -> String:
		var datetime := Time.get_datetime_dict_from_unix_time(created_at)
		return "%04d-%02d-%02d %02d:%02d" % [
			datetime.year, datetime.month, datetime.day,
			datetime.hour, datetime.minute
		]
