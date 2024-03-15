extends ConfirmationDialog


signal imported(project_path, editor_path, and_edit, callback)


@onready var _browse_project_path_button: Button = %BrowseProjectPathButton
@onready var _browse_project_path_dialog: FileDialog = $BrowseProjectPathDialog
@onready var _project_path_edit: LineEdit = %ProjectPathEdit
@onready var _editors_option_button: OptionButton = $VBoxContainer/HBoxContainer2/EditorsOptionButton
@onready var _version_hint_value = %VersionHintValue
@onready var _version_hint_container = %VersionHintContainer

var _editor_options = []
var _callback = null


func _ready() -> void:
#	super._ready()
	min_size = Vector2i(300, 0) * Config.EDSCALE
	_update_ok_button_available()
	_browse_project_path_button.pressed.connect(func():
		if _project_path_edit.text.is_empty():
			_browse_project_path_dialog.current_dir = ProjectSettings.globalize_path(
				Config.DEFAULT_PROJECTS_PATH.ret()
			)
		else:
			_browse_project_path_dialog.current_path = _project_path_edit.text
		_browse_project_path_dialog.popup_centered_ratio(0.5)
	)
	_browse_project_path_button.icon = get_theme_icon("Load", "EditorIcons")
	_browse_project_path_dialog.file_selected.connect(func(path):
		_project_path_edit.text = path
		_update_ok_button_available()
		_sort_options()
	)
	_editors_option_button.item_selected.connect(func(_arg): 
		_update_ok_button_available()
	)
	_project_path_edit.text_changed.connect(func(arg: String):
		_update_ok_button_available()
		_sort_options()
	)
	
	visibility_changed.connect(func():
		if not visible:
			_callback = null
	)
	
	custom_action.connect(func(action):
		if action == "just_import":
			imported.emit(
				_project_path_edit.text, 
				_editors_option_button.get_item_metadata(_editors_option_button.selected),
				false,
				_callback
			)
			hide()
	)

	add_button(tr("Import"), false, "just_import")


func init(project_path, editor_options, callback=null):
	_callback = callback
	_editor_options = editor_options
	_set_editor_options(editor_options)
	_project_path_edit.clear()
	_project_path_edit.text = project_path
	_update_ok_button_available()
	_sort_options()


func _set_editor_options(options):
	_editors_option_button.clear()
	for idx in range(len(options)):
		var opt = options[idx]
		_editors_option_button.add_item(opt.label)
		_editors_option_button.set_item_metadata(idx, opt.path)


func _on_confirmed() -> void:
	imported.emit(
		_project_path_edit.text, 
		_editors_option_button.get_item_metadata(_editors_option_button.selected),
		true,
		_callback
	)


func _update_ok_button_available():
	get_ok_button().disabled = _editors_option_button.selected == -1 or _project_path_edit.text.get_extension() != "godot"


func _sort_options():
	if _project_path_edit.text.get_extension() == "godot":
		var cfg = Projects.ExternalProjectInfo.new(_project_path_edit.text)
		cfg.load(false)
		cfg.sort_editor_options(_editor_options)
		if cfg.has_version_hint:
			_version_hint_value.text = cfg.version_hint
			_version_hint_container.show()
		else:
			_version_hint_container.hide()
		_set_editor_options(_editor_options)
	else:
		_version_hint_container.hide()
