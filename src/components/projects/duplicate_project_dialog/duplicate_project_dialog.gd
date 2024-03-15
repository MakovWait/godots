extends "res://src/components/projects/install_project_dialog/install_project_dialog.gd"


signal duplicated(path)


@onready var _rename_check_box: CheckBox = %RenameCheckBox
var _cache_should_rename = Cache.smart_value(self, "rename_duple", true)
var _project: Projects.Item


func _ready():
	super._ready()
	_rename_check_box.button_pressed = _cache_should_rename.ret(false)
	get_ok_button().text = tr("Duplicate")
	dialog_hide_on_ok = false

	visibility_changed.connect(func():
		if not visible:
			_project = null
	)

	confirmed.connect(func():
		var final_project_name = _project_name_edit.text.strip_edges()
		var project_dir = _project_path_line_edit.text.strip_edges()

		var err = 0
		if OS.has_feature("macos") or OS.has_feature("linux"):
			err = OS.execute("cp", ["-r", _project.path.get_base_dir().path_join("."), project_dir])
		elif OS.has_feature("windows"):
			err = OS.execute(
				"powershell.exe", 
				[
					"-command",
					"\"Copy-Item -Path '%s' -Destination '%s' -Recurse\"" % [ 
						ProjectSettings.globalize_path(_project.path.get_base_dir().path_join("*")), 
						ProjectSettings.globalize_path(project_dir)
					]
				]
			)
		if err != 0:
			error(tr("Error. Code: %s" % err))
			return

		var project_configs = utils.find_project_godot_files(project_dir)
		if len(project_configs) == 0:
			error(tr("No project.godot found."))
			return
		
		_cache_should_rename.put(_rename_check_box.button_pressed)
		hide()
		
		var project_file_path = project_configs[0]
		duplicated.emit(
			project_file_path.path,
			func(imported_project: Projects.Item, projects: Projects.List):
				if _rename_check_box.button_pressed:
					imported_project.name = final_project_name
					imported_project.emit_internals_changed()
					projects.save()
		)
	)


func _on_raise(args=null):
	_project = args
	title = "Duplicate Project: %s" % _project.name
