extends HBoxListItem

signal edited
signal removed
signal manage_tags_requested
signal duplicate_requested
signal tag_clicked(tag)

@export var _rename_dialog_scene: PackedScene

@onready var _path_label: Label = %PathLabel
@onready var _title_label: Label = %TitleLabel
@onready var _explore_button: Button = %ExploreButton
@onready var _favorite_button: TextureButton = $Favorite/FavoriteButton
@onready var _icon: TextureRect = $Icon
@onready var _editor_path_label: Label = %EditorPathLabel
@onready var _editor_button: Button = %EditorButton
@onready var _project_warning: TextureRect = %ProjectWarning
@onready var _tag_container: HBoxContainer = %TagContainer
@onready var _project_features: Label = %ProjectFeatures
@onready var _info_body = %InfoBody
@onready var _info_v_box = %InfoVBox
@onready var _actions_h_box = %ActionsHBox
@onready var _title_container: HBoxContainer = %TitleContainer
@onready var _actions_container: HBoxContainer = %ActionsContainer

static var settings := ProjectItemActions.Settings.new(
	'project-item-inline-actions',
	[]
)

var _actions: Action.List
var _tags = []
var _sort_data = {
	'ref': self
}

func _ready() -> void:
	super._ready()
	_info_body.add_theme_constant_override("separation", int(-12 * Config.EDSCALE))
	_project_features.add_theme_font_override("font", get_theme_font("title", "EditorFonts"))
	_project_features.add_theme_color_override(
		"font_color", get_theme_color("warning_color", "Editor")
	)
	_editor_button.icon = get_theme_icon("GodotMonochrome", "EditorIcons")
	_project_warning.texture = get_theme_icon("NodeWarning", "EditorIcons")
	_project_warning.tooltip_text = tr("Editor is missing.")
	_tag_container.tag_clicked.connect(func(tag): tag_clicked.emit(tag))


func init(item: Projects.Item):
	_fill_actions(item)
	_setup_actions_view(item)

	item.loaded.connect(func():
		_fill_data(item)
	)
	
	_editor_button.pressed.connect(_on_rebind_editor.bind(item))
	_editor_button.disabled = item.is_missing
	
	item.internals_changed.connect(func():
		_fill_data(item)
	)

	_fill_data(item)
	
	_explore_button.pressed.connect(func():
		OS.shell_show_in_file_manager(ProjectSettings.globalize_path(item.path).get_base_dir())
	)
	_favorite_button.toggled.connect(func(is_favorite):
		item.favorite = is_favorite
		edited.emit()
	)
	double_clicked.connect(func():
		if item.is_missing:
			return
		
		if item.has_invalid_editor:
			_on_rebind_editor(item)
		else:
			_on_edit_with_editor(item)
	)


func _setup_actions_view(item: Projects.Item):
	var action_views = ProjectItemActions.Menu.new(
		_actions.without(['view-command']).all(), 
		settings, 
		CustomCommandsPopupItems.Self.new(
			_actions.by_key('view-command'),
			_get_commands(item)
		)
	)
	action_views.icon = get_theme_icon("GuiTabMenuHl", "EditorIcons")
	action_views.add_controls_to_node(_actions_h_box)
	_actions_container.add_child(action_views)

	var set_actions_visible = func(v):
		_actions_h_box.visible = v
		action_views.visible = v
	right_clicked.connect(func():
		action_views.refill_popup()
		var popup = action_views.get_popup()
		var rect = Rect2(Vector2(DisplayServer.mouse_get_position()), Vector2.ZERO)
		popup.size = rect.size
		if is_layout_rtl():
			rect.position.x += rect.size.y - popup.y
		popup.position = rect.position
		popup.popup()
	)
	selected_changed.connect(func(is_selected):
		if settings.is_show_always(): return
		set_actions_visible.call(_is_hovering or is_selected)
	)
	set_actions_visible.call(settings.is_show_always())
	hover_changed.connect(func(is_hovered):
		if settings.is_show_always(): return
		set_actions_visible.call(is_hovered or _is_selected)
	)
	var sync_settings = func():
		if settings.is_show_always():
			set_actions_visible.call(true)
		else:
			set_actions_visible.call(_is_hovering or _is_selected)
		_actions_h_box.remove_theme_constant_override("separation")
		_actions_container.remove_theme_constant_override("separation")
		_actions_h_box.modulate = Color.WHITE
		action_views.modulate = Color.WHITE
		if settings.is_flat() and not settings.is_show_text():
			_actions_h_box.add_theme_constant_override("separation", int(-4 * Config.EDSCALE))
			_actions_container.add_theme_constant_override("separation", int(-4 * Config.EDSCALE))
			_actions_h_box.modulate = Color(1, 1, 1, 0.498)
			action_views.modulate = Color(1, 1, 1, 0.498)
		_tag_container.visible = settings.is_show_tags()
		_project_features.visible = settings.is_show_features()
	sync_settings.call()
	settings.changed.connect(sync_settings)


func _fill_actions(item: Projects.Item):
	var edit = Action.from_dict({
		"key": "edit",
		"icon": Action.IconTheme.new(self, "Edit", "EditorIcons"),
		"act": _on_edit_with_editor.bind(item),
		"label": tr("Edit"),
	})
	
	var run = Action.from_dict({
		"key": "run",
		"icon": Action.IconTheme.new(self, "Play", "EditorIcons"),
		"act": _on_run_with_editor.bind(item, func(item): item.run(), "run", "Run", false),
		"label": tr("Run"),
	})

	var duplicate = Action.from_dict({
		"key": "duplicate",
		"icon": Action.IconTheme.new(self, "Duplicate", "EditorIcons"),
		"act": func(): duplicate_requested.emit(),
		"label": tr("Duplicate"),
	})

	var rename = Action.from_dict({
		"key": "rename",
		"icon": Action.IconTheme.new(self, "Rename", "EditorIcons"),
		"act": _on_rename.bind(item),
		"label": tr("Rename"),
	})

	var bind_editor = Action.from_dict({
		"key": "bind-editor",
		"icon": Action.IconTheme.new(self, "GodotMonochrome", "EditorIcons"),
		"act": _on_rebind_editor.bind(item),
		"label": tr("Bind Editor"),
	})

	var manage_tags = Action.from_dict({
		"key": "manage-tags",
		"icon": Action.IconTheme.new(self, "Script", "EditorIcons"),
		"act": func(): manage_tags_requested.emit(),
		"label": tr("Manage Tags"),
	})
	
	var view_command = Action.from_dict({
		"key": "view-command",
		"icon": Action.IconTheme.new(self, "Edit", "EditorIcons"),
		"act": _view_command.bind(item),
		"label": tr("Edit Commands"),
	})
	
	var remove = Action.from_dict({
		"key": "remove",
		"icon": Action.IconTheme.new(self, "Remove", "EditorIcons"),
		"act": _on_remove,
		"label": tr("Remove"),
	})

	_actions = Action.List.new([
		edit,
		run,
		duplicate,
		rename,
		bind_editor,
		manage_tags,
		view_command,
		remove
	])


func _fill_data(item: Projects.Item):
	if item.is_missing:
		_explore_button.icon = get_theme_icon("FileBroken", "EditorIcons")
		modulate = Color(1, 1, 1, 0.498)
		
	_project_warning.visible = item.has_invalid_editor
	_favorite_button.button_pressed = item.favorite
	_title_label.text = item.name
	_editor_path_label.text = item.editor_name
	_path_label.text = item.path
	_icon.texture = item.icon
	_tag_container.set_tags(item.tags)
	_set_features(item.features)
	_tags = item.tags
	
	_sort_data.favorite = item.favorite
	_sort_data.name = item.name
	_sort_data.path = item.path
	_sort_data.last_modified = item.last_modified
	_sort_data.tag_sort_string = "".join(item.tags)
	
	for action in _actions.sub_list([
		'duplicate',
		'bind-editor',
		'manage-tags',
		'rename'
	]).all():
		action.disable(item.is_missing)
	
	for action in _actions.sub_list([
		'view-command',
		'edit',
		'run',
	]).all():
		action.disable(item.is_missing or item.has_invalid_editor)


func _view_command(item: Projects.Item):
	var command_viewer = Context.use(self, CommandViewer) as CommandViewer
	if command_viewer:
		command_viewer.raise(
			_get_commands(item), true
		)


func _get_commands(item: Projects.Item) -> CommandViewer.Commands:
	var base_process_src = OSProcessSchema.FmtSource.new(item)
	var cmd_src = CommandViewer.CustomCommandsSourceDynamic.new(item)
	cmd_src.edited.connect(func(): edited.emit())
	var commands = CommandViewer.CommandsDuo.new(
		CommandViewer.CommandsGeneric.new(
			base_process_src,
			cmd_src,
			true
		),
		CommandViewer.CommandsGeneric.new(
			base_process_src,
			Config.CustomCommandsSourceConfig.new(
				Config.GLOBAL_CUSTOM_COMMANDS_PROJECTS
			),
			false
		)
	)
	return commands


func _set_features(features):
	var features_to_print = Array(features).filter(func(x): return _is_version(x) or x == "C#")
	if len(features_to_print) > 0:
		var str = ", ".join(features_to_print)
		_project_features.text = str
#		_project_features.custom_minimum_size = Vector2(25 * 15, 10) * Config.EDSCALE
		if settings.is_show_features():
			_project_features.show()
	else:
		_project_features.hide()


func _is_version(feature: String):
	return feature.contains(".") and feature.substr(0, 3).is_valid_float()


func _on_rebind_editor(item):
	var bind_dialog = ConfirmationDialogAutoFree.new()
	
	var vbox = VBoxContainer.new()
	bind_dialog.add_child(vbox)
	
	var hbox = HBoxContainer.new()
	vbox.add_child(hbox)
	
	var title = Label.new()
	hbox.add_child(title)
	
	var options = OptionButton.new()
	hbox.add_child(options)
	
	if item.has_version_hint:
		var hbox2 = HBoxContainer.new()
		hbox2.modulate = Color(0.5, 0.5, 0.5, 0.5)
		hbox2.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_child(hbox2)
		
		var version_hint_title = Label.new()
		version_hint_title.text = tr("version hint:")
		hbox2.add_child(version_hint_title)
		
		var version_hint_value = Label.new()
		version_hint_value.text = item.version_hint
		hbox2.add_child(version_hint_value)
	
	vbox.add_spacer(false)
	
	title.text = "%s: " % tr("Editor")
	
	options.item_selected.connect(func(idx):
		bind_dialog.get_ok_button().disabled = false
	)
	var option_items = item.editors_to_bind
	bind_dialog.get_ok_button().disabled = len(option_items) == 0
	for i in len(option_items):
		var opt = option_items[i]
		options.add_item(opt.label, i)
		options.set_item_metadata(i, opt.path)
	
	bind_dialog.confirmed.connect(func():
		if options.selected < 0: return
		var new_editor_path = options.get_item_metadata(options.selected)
		item.editor_path = new_editor_path
		edited.emit()
	)
	
	add_child(bind_dialog)
	bind_dialog.popup_centered()


func _on_rename(item):
	var dialog = _rename_dialog_scene.instantiate()
	add_child(dialog)
	dialog.popup_centered()
	dialog.init(item.name, item.version_hint)
	dialog.editor_renamed.connect(func(new_name, version_hint):
		item.name = new_name
		item.version_hint = version_hint
		edited.emit()
	)


func _on_edit_with_editor(item):
	_on_run_with_editor(item, func(item): item.edit(), "edit", "Edit", true)


func _on_run_with_editor(item, editor_flag, action_name, ok_button_text, auto_close):
	if not item.show_edit_warning:
		_run_with_editor(item, editor_flag, auto_close)
		return
	
	var confirmation_dialog = ConfirmationDialogAutoFree.new()
	confirmation_dialog.ok_button_text = ok_button_text
	confirmation_dialog.get_label().hide()
	
	var label = Label.new()
	label.text = tr("Are you sure to %s the project with the given editor?") % action_name
	
	var editor_name = Label.new()
	editor_name.text = item.editor_name
	editor_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	var checkbox = CheckBox.new()
	checkbox.text = tr("do not show again for this project")
	
	var vb = VBoxContainer.new()
	vb.add_child(label)
	vb.add_child(editor_name)
	vb.add_child(checkbox)
	vb.add_spacer(false)
	
	confirmation_dialog.add_child(vb)
	
	confirmation_dialog.confirmed.connect(func():
		var before = item.show_edit_warning
		item.show_edit_warning = not checkbox.button_pressed
		if item.show_edit_warning != before:
			edited.emit()
		_run_with_editor(item, editor_flag, auto_close)
	)
	add_child(confirmation_dialog)
	confirmation_dialog.popup_centered()
	

func _run_with_editor(item: Projects.Item, editor_flag, auto_close):
	editor_flag.call(item)

	if auto_close:
		AutoClose.close_if_should()


func _on_remove():
	var confirmation_dialog = ConfirmationDialogAutoFree.new()
	confirmation_dialog.ok_button_text = tr("Remove")
	confirmation_dialog.dialog_text = tr("Are you sure to remove the project from the list?")
	confirmation_dialog.confirmed.connect(func():
		queue_free()
		removed.emit()
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


class RunButton extends Button:
	func init(item):
		disabled = item.has_invalid_editor or item.is_missing
		item.internals_changed.connect(func():
			disabled = item.has_invalid_editor or item.is_missing
		)
		if item.has_invalid_editor:
			tooltip_text = tr("Bind editor first.")

