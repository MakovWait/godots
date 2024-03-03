extends HBoxListItem

signal edited
signal removed(remove_dir: bool)
signal manage_tags_requested
signal tag_clicked(tag)


@export var _rename_dialog_scene: PackedScene
@export var _add_extra_arguments_scene: PackedScene

@onready var _path_label: Label = %PathLabel
@onready var _title_label: Label = %TitleLabel
@onready var _explore_button: Button = %ExploreButton
@onready var _favorite_button: TextureButton = %FavoriteButton
@onready var _tag_container: HBoxContainer = %TagContainer
@onready var _editor_features = %EditorFeatures

var _actions: Action.List
var _tags = []
var _sort_data = {
	'ref': self
}


func _ready():
	super._ready()
	_tag_container.tag_clicked.connect(func(tag): tag_clicked.emit(tag))
	
	_editor_features.add_theme_font_override("font", get_theme_font("title", "EditorFonts"))
	_editor_features.add_theme_color_override("font_color", get_theme_color("warning_color", "Editor"))


func init(item: LocalEditors.Item):
	_fill_actions(item)
	_update_actions_availability(item)
	
	if not item.is_valid:
		_explore_button.icon = get_theme_icon("FileBroken", "EditorIcons")
		modulate = Color(1, 1, 1, 0.498)
	
	item.tags_edited.connect(func():
		_tag_container.set_tags(item.tags)
		_tags = item.tags
		_sort_data.tag_sort_string = "".join(item.tags)
	)
	
	_title_label.text = item.name
	_path_label.text = item.path
	_favorite_button.button_pressed = item.favorite
	_tag_container.set_tags(item.tags)
	_tags = item.tags
	
	if item.is_self_contained():
		_editor_features.text = tr("Self-contained")
		_editor_features.show()
	else:
		_editor_features.hide()

	_sort_data.favorite = item.favorite
	_sort_data.name = item.name
	_sort_data.path = item.path
	_sort_data.tag_sort_string = "".join(item.tags)
	
	_explore_button.pressed.connect(func():
		OS.shell_show_in_file_manager(ProjectSettings.globalize_path(item.path).get_base_dir())
	)
	_favorite_button.toggled.connect(func(is_favorite):
		_sort_data.favorite = is_favorite
		item.favorite = is_favorite
		edited.emit()
	)
	double_clicked.connect(func():
		if item.is_valid:
			_on_run_editor(item)
	)


func _fill_actions(item: LocalEditors.Item):
	var run = Action.from_dict({
		"key": "run",
		"icon": Action.IconTheme.new(self, "Play", "EditorIcons"),
		"act": _on_run_editor.bind(item),
		"label": tr("Run"),
	})
	
	var rename = Action.from_dict({
		"key": "rename",
		"icon": Action.IconTheme.new(self, "Rename", "EditorIcons"),
		"act": _on_rename.bind(item),
		"label": tr("Rename"),
	})

	var manage_tags = Action.from_dict({
		"key": "manage-tags",
		"icon": Action.IconTheme.new(self, "Script", "EditorIcons"),
		"act": func(): manage_tags_requested.emit(),
		"label": tr("Manage Tags"),
	})

	var add_extra_arguments = Action.from_dict({
		"key": "add-extra-args",
		"icon": Action.IconTheme.new(self, "ConfirmationDialog", "EditorIcons"),
		"act": _on_add_extra_arguments.bind(item),
		"label": tr("Add Extra Args"),
	})

	var view_command = Action.from_dict({
		"key": "view-command",
		"icon": Action.IconTheme.new(self, "Window", "EditorIcons"),
		"act": _view_command.bind(item),
		"label": tr("View Command"),
	})
	
	var remove = Action.from_dict({
		"key": "remove",
		"icon": Action.IconTheme.new(self, "Remove", "EditorIcons"),
		"act": _on_remove.bind(item),
		"label": tr("Remove"),
	})

	_actions = Action.List.new([
		run,
		rename,
		manage_tags,
		add_extra_arguments,
		view_command,
		remove
	])


func _update_actions_availability(item: LocalEditors.Item):
	for action in _actions.sub_list([
		'run',
		'manage-tags',
		'rename',
		'add-extra-args',
		'view-command'
	]).all():
		action.disable(not item.is_valid)


func _view_command(item):
	var command_viewer = Context.use(self, CommandViewer) as CommandViewer
	if command_viewer:
		var base_process = item.as_process([])
		var cmd_src = CommandViewer.CustomCommandsSourceDynamic.new(item)
		cmd_src.edited.connect(func(): edited.emit())
		var commands = CommandViewer.CommandsDuo.new(
			CommandViewer.CommandsGeneric.new(
				base_process,
				cmd_src,
				true
			),
			CommandViewer.CommandsGeneric.new(
				base_process,
				Config.CustomCommandsSourceConfig.new(
					Config.GLOBAL_CUSTOM_COMMANDS_EDITORS
				),
				false
			)
		)
		command_viewer.raise(
			commands, true
		)


func _on_run_editor(item):
	item.as_project_manager_process().create_process()
	AutoClose.close_if_should()


func _on_rename(item):
	var dialog = _rename_dialog_scene.instantiate()
	add_child(dialog)
	dialog.popup_centered()
	dialog.init(item.name, item.version_hint)
	dialog.editor_renamed.connect(func(new_name, version_hint):
		item.name = new_name
		item.version_hint = version_hint
		_title_label.text = item.name
		edited.emit()
	)

func _on_add_extra_arguments(item):
	var dialog = _add_extra_arguments_scene.instantiate()
	add_child(dialog)
	dialog.popup_centered()
	dialog.init(item.extra_arguments)
	dialog.editor_add_extra_arguments.connect(func(new_extra_arguments):
		item.extra_arguments = new_extra_arguments
		edited.emit()
	)

func _on_remove(item):
	var confirmation_dialog = ConfirmationDialogAutoFree.new()
	confirmation_dialog.ok_button_text = tr("Remove")
	confirmation_dialog.get_label().hide()
	
	var label = Label.new()
	label.text = tr("Are you sure to remove the editor from the list?")
	
	var warning = Label.new()
	warning.text = tr("NOTE: the action will remove the parent folder of the editor with all the content.") + "\n%s" % item.path.get_base_dir()
	warning.self_modulate = get_theme_color("warning_color", "Editor")
	warning.hide()
	
	var checkbox = CheckBox.new()
	checkbox.text = tr("remove also from the file system")
	checkbox.toggled.connect(func(toggled):
		warning.visible = toggled
	)
	
	var vb = VBoxContainer.new()
	vb.add_child(label)
	vb.add_child(checkbox)
	vb.add_child(warning)
	vb.add_spacer(false)
	
	confirmation_dialog.add_child(vb)
	
	confirmation_dialog.confirmed.connect(func():
		queue_free()
		removed.emit(checkbox.button_pressed)
	)
	add_child(confirmation_dialog)
	confirmation_dialog.popup_centered()


func get_actions():
	return []


func apply_filter(filter):
	return filter.call({
		'name': _title_label.text,
		'path': _path_label.text,
		'tags': _tags
	})


func get_sort_data():
	return _sort_data
