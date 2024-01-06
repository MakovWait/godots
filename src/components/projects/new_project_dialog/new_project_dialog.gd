extends "res://src/components/projects/install_project_dialog/install_project_dialog.gd"

signal created(path)

@onready var _svg_check_box: CheckBox = %SvgCheckBox
const ICON_SVG := """<svg height="128" width="128" xmlns="http://www.w3.org/2000/svg"><rect x="2" y="2" width="124" height="124" rx="14" fill="#363d52" stroke="#212532" stroke-width="4"/><g transform="scale(.101) translate(122 122)"><g fill="#fff"><path d="M105 673v33q407 354 814 0v-33z"/><path fill="#478cbf" d="m105 673 152 14q12 1 15 14l4 67 132 10 8-61q2-11 15-15h162q13 4 15 15l8 61 132-10 4-67q3-13 15-14l152-14V427q30-39 56-81-35-59-83-108-43 20-82 47-40-37-88-64 7-51 8-102-59-28-123-42-26 43-46 89-49-7-98 0-20-46-46-89-64 14-123 42 1 51 8 102-48 27-88 64-39-27-82-47-48 49-83 108 26 42 56 81zm0 33v39c0 276 813 276 813 0v-39l-134 12-5 69q-2 10-14 13l-162 11q-12 0-16-11l-10-65H447l-10 65q-4 11-16 11l-162-11q-12-3-14-13l-5-69z"/><path d="M483 600c3 34 55 34 58 0v-86c-3-34-55-34-58 0z"/><circle cx="725" cy="526" r="90"/><circle cx="299" cy="526" r="90"/></g><g fill="#414042"><circle cx="307" cy="532" r="60"/><circle cx="717" cy="532" r="60"/></g></g></svg>"""

func _ready():
	super._ready()
	_svg_check_box.button_pressed = Cache.smart_value(self, "use_svg", true).ret(false)
	
	confirmed.connect(func():
		var dir = _project_path_line_edit.text.strip_edges()
		var project_file_path = dir.path_join("project.godot")

		var initial_settings = ConfigFile.new()
		initial_settings.set_value("application", "config/name", _project_name_edit.text.strip_edges())
		if _svg_check_box.button_pressed:
			initial_settings.set_value("application", "config/icon", "res://icon.svg")
		else:
			initial_settings.set_value("application", "config/icon", "res://icon.png")
		var err = initial_settings.save(project_file_path)
		if err:
			_error("%s %s: %s." % [
				tr("Couldn't create project.godot in project path."), tr("Code"), err
			])
			return
		else:
			if _svg_check_box.button_pressed:
				var file_to = FileAccess.open(dir.path_join("icon.svg"), FileAccess.WRITE)
				file_to.store_string(ICON_SVG)
				file_to.close()
			else:
				var img: Texture2D = preload("res://assets/default_project_icon.svg")
				img.get_image().save_png(dir.path_join("icon.png"))
			created.emit(project_file_path)
			Cache.smart_value(self, "use_svg", true).put(_svg_check_box.button_pressed)
	)
