class_name GodotsInstall


class I:
	func install(abs_zip_path: String) -> void:
		pass


class Default extends I:
	const uuid = preload("res://addons/uuid.gd")
	
	var _current_exe_path: String
	var _tree: SceneTree
	
	func _init(current_exe_path: String, tree: SceneTree) -> void:
		_current_exe_path = current_exe_path
		_tree = tree
	
	func install(abs_zip_path: String) -> void:
		var unzip_dir := (Config.UPDATES_PATH.ret() as String).path_join("godots-update")
		if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(unzip_dir)):
			unzip_dir += "-%s" % uuid.v4().substr(0, 8)
		unzip_dir += "/"
		
		zip.unzip(abs_zip_path, unzip_dir)
		if OS.has_feature("macos"):
			# weired stuff since macOs.zip is nested: macOs.zip -> Godots.zip -> Godots.app o:
			zip.unzip(unzip_dir.path_join("Godots.zip"), unzip_dir)
		
		if OS.has_feature("windows"):
			var downloaded_exe_path := ProjectSettings.globalize_path(
				unzip_dir.path_join("Godots.exe")
			)
			DirAccess.rename_absolute(_current_exe_path, _current_exe_path + ".old")
			DirAccess.copy_absolute(downloaded_exe_path, _current_exe_path)
			_tree.quit()
			OS.create_process(_current_exe_path, [])
		elif OS.has_feature("linux"):
			var downloaded_exe_path := ProjectSettings.globalize_path(
				unzip_dir.path_join("Godots.x86_64")
			)
			DirAccess.rename_absolute(_current_exe_path, _current_exe_path + ".old")
			DirAccess.copy_absolute(downloaded_exe_path, _current_exe_path)
			OS.execute(
				"chmod", 
				["+x", "%s" % ProjectSettings.globalize_path(_current_exe_path) ],
			)
			_tree.quit()
			OS.create_process(_current_exe_path, [])
		elif OS.has_feature("macos"):
			var app_path := _current_exe_path.get_base_dir().get_base_dir().get_base_dir()
			if not app_path.ends_with(".app"):
				# TODO notify something went wrong
				return
			var parent_app_dir := app_path.get_base_dir()
			var downloaded_app_path := ProjectSettings.globalize_path(
				unzip_dir.path_join("Godots.app")
			)
			OS.execute("cp", ["-rf", downloaded_app_path, parent_app_dir])
			_tree.quit()
#			OS.create_process(_current_exe_path, [])


class Forbidden extends I:
	var _node: Node
	
	func _init(node: Node) -> void:
		_node = node
	
	func install(abs_zip_path: String) -> void:
		var dialog := ConfirmationDialogAutoFree.new()
		dialog.title = tr("Alert!")
		dialog.dialog_text = tr("Installing is forbidden!")
		_node.add_child(dialog)
		dialog.popup_centered()
