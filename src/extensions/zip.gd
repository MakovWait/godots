class_name zip

static func unzip(zip_path: String, target_dir: String) -> void:
	DirAccess.make_dir_absolute(target_dir)
	DirAccess.make_dir_absolute(zip_path)
	var reader: ZIPReader = ZIPReader.new()
	var err : Error = reader.open(zip_path)
	unzip_to_path(reader, target_dir)
	
	
	


## A procedure that unzips a zip file to a target directory, keeping the
## target directory as root, rather than the zip's root directory.
static func unzip_to_path(zip: ZIPReader, destiny: String) -> Error:
	var files := zip.get_files()
	var err: int

	for zip_file_name in files:
		if zip_file_name == files[0]:
			continue
		var target_file_name := destiny.path_join(zip_file_name.split("/", false, 1)[1])
		if zip_file_name.ends_with("/"):
			err = DirAccess.make_dir_recursive_absolute(target_file_name)
			if err != OK:
				return err
		else:
			var file_contents := zip.read_file(zip_file_name)
			var file := FileAccess.open(target_file_name, FileAccess.WRITE)
			if not file:
				return FileAccess.get_open_error()
			file.store_buffer(file_contents)
			file.close()
	return OK
