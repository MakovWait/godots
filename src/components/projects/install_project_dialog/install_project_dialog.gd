extends ConfirmationDialog


@onready var _project_name_edit = %ProjectNameEdit
@onready var _create_folder_button = %CreateFolderButton
@onready var _browse_project_path_button = %BrowseProjectPathButton
@onready var _project_path_line_edit = %ProjectPathLineEdit
@onready var _message_label = %MessageLabel
@onready var _status_rect = %StatusRect
@onready var _create_folder_failed_dialog = $CreateFolderFailedDialog
@onready var _file_dialog = $FileDialog

var _create_folder_failed_label: Label

func _ready():
	_create_folder_failed_label = Label.new()
	_create_folder_failed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_create_folder_failed_dialog.add_child(_create_folder_failed_label)
	
	_project_path_line_edit.text_changed.connect(func(_arg): _validate())
	_create_folder_button.pressed.connect(func():
		var path = _project_path_line_edit.text.strip_edges()
		var dir = DirAccess.open(path)
		if dir:
			var err = dir.make_dir(_project_name_edit.text)
			if err > 0:
				_create_folder_failed_label.text = "%s %s: %s." % [
					tr("Couldn't create folder."),
					tr("Code"),
					err
				]
				_create_folder_failed_dialog.popup_centered()
			elif err == OK:
				_project_path_line_edit.text = path.path_join(_project_name_edit.text)
				_validate()
	)
	
	_browse_project_path_button.pressed.connect(func():
		_file_dialog.current_dir = _project_path_line_edit.text.strip_edges()
		_file_dialog.popup_centered_ratio(0.5)
	)
	_file_dialog.dir_selected.connect(func(dir): 
		_project_path_line_edit.text = dir
		_validate()
	)
	
	min_size = Vector2(640, 215) * Config.EDSCALE


func raise(project_name="New Game Project"):
	_project_name_edit.text = project_name
	_project_path_line_edit.text = Config.DEFAULT_PROJECTS_PATH.ret()
	popup_centered()
	_validate()


func _validate():
	var path = _project_path_line_edit.text.strip_edges()
	var dir = DirAccess.open(path)
	
	if not dir:
		_error(tr("The path specified doesn't exist."))
		return
	
	if path.simplify_path() in [OS.get_environment("HOME"), OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS), OS.get_executable_path().get_base_dir()].filter(func(x): return x.simplify_path()):
		_error(tr(
			"You cannot save a project in the selected path. Please make a new folder or choose a new path."
		))
		return

	# Check if the specified folder is empty, even though this is not an error, it is good to check here.
	var dir_is_empty = true
	dir.list_dir_begin()
	var n = dir.get_next()
	while not n.is_empty():
		if not n.begins_with("."):
			# Allow `.`, `..` (reserved current/parent folder names)
			# and hidden files/folders to be present.
			# For instance, this lets users initialize a Git repository
			# and still be able to create a project in the directory afterwards.
			dir_is_empty = false
			break;
		n = dir.get_next()
	dir.list_dir_end()

	if not dir_is_empty:
		if _handle_dir_is_not_empty(path):
			return
	
	_success("")


func error(text):
	_error(text)


func _error(text):
	_set_message(text, "error")
	get_ok_button().disabled = true


func _warning(text):
	_set_message(text, "warning")
	get_ok_button().disabled = false


func _success(text):
	_set_message(text, "success")
	get_ok_button().disabled = false


func _set_message(text, type):
	var new_icon = null
	if type == "error":
		_message_label.add_theme_color_override("font_color", get_theme_color("error_color", "Editor"))
		_message_label.modulate = Color(1, 1, 1, 1)
		new_icon = get_theme_icon("StatusError", "EditorIcons")
	elif type == "success":
		_message_label.remove_theme_color_override("font_color")
		_message_label.modulate = Color(1, 1, 1, 0)
		new_icon = get_theme_icon("StatusSuccess", "EditorIcons")
	elif type == "warning":
		_message_label.add_theme_color_override("font_color", get_theme_color("warning_color", "Editor"))
		_message_label.modulate = Color(1, 1, 1, 1)
		new_icon = get_theme_icon("StatusWarning", "EditorIcons")
	_message_label.text = text
	_status_rect.texture = new_icon
	
	var window_size = size
	var contents_min_size = get_contents_minimum_size()
	if window_size.x < contents_min_size.x or window_size.y < contents_min_size.y:
		size = Vector2(
			max(window_size.x, contents_min_size.x), 
			max(window_size.y, contents_min_size.y)
		)


func _handle_dir_is_not_empty(_path):
	_warning(tr(
		"The selected path is not empty. Choosing an empty folder is highly recommended."
	))
	return true
