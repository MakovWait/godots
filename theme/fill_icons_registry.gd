@tool
extends EditorScript


func _run() -> void:
	_create_cfg('res://theme/icons', 'res://theme/icons.cfg')
	_create_cfg('res://theme/icons-light', 'res://theme/icons-light.cfg')


func _create_cfg(icons_dir, result_file_path):
	var result = ConfigFile.new()
	var dir = EditorInterface.get_resource_filesystem().get_filesystem_path(icons_dir)
	for i in range(dir.get_file_count()):
		var path = dir.get_file_path(i)
		result.set_value(path, "name", path.get_basename().get_file())
	result.save(result_file_path)
