# https://www.davidepesce.com/?p=1365
static func remove_recursive(path):
	var directory = DirAccess.open(path)
	# Open directory
	var error = DirAccess.get_open_error()
	if error == OK:
		directory.include_hidden = true
		# List directory content
		directory.list_dir_begin()
		var file_name = directory.get_next()
		while file_name != "":
			if directory.current_is_dir():
				remove_recursive(path + "/" + file_name)
			else:
				directory.remove(file_name)
			file_name = directory.get_next()
		
		# Remove current path
		directory.remove(path)
	else:
		print("Error removing " + path)


static func path_is_valid(abs_path):
	return DirAccess.dir_exists_absolute(abs_path) or FileAccess.file_exists(abs_path)
