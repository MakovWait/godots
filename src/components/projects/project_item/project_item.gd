extends HBoxListItem

signal edited
signal removed
signal manage_tags_requested
signal tag_clicked(tag)

const buttons = preload("res://src/extensions/buttons.gd")
const projects_ns = preload("res://src/services/projects.gd")


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

var _get_actions_callback: Callable
var _tags = []
var _sort_data = {
	'ref': self
}


func _ready() -> void:
	super._ready()
	_info_body.add_theme_constant_override("separation", int(-12 * Config.EDSCALE))
	_project_features.add_theme_font_override("font", get_theme_font("title", "EditorFonts"))
	_project_features.add_theme_color_override("font_color", get_theme_color("warning_color", "Editor"))
	_editor_button.icon = get_theme_icon("GodotMonochrome", "EditorIcons")
	_project_warning.texture = get_theme_icon("NodeWarning", "EditorIcons")
	_project_warning.tooltip_text = tr("Editor is missing.")
	_tag_container.tag_clicked.connect(func(tag): tag_clicked.emit(tag))


func init(item: projects_ns.Project):
	if item.is_missing:
		_explore_button.icon = get_theme_icon("FileBroken", "EditorIcons")
		modulate = Color(1, 1, 1, 0.498)

	item.loaded.connect(func():
		_fill_data(item)
	)

	item.internals_changed.connect(func():
		_fill_data(item)
	)

	_fill_data(item)
	
	_get_actions_callback = func():
		if not item.is_loaded:
			return []

		var edit_btn = buttons.simple(
			tr("Edit"), 
			get_theme_icon("Edit", "EditorIcons"),
			_on_edit_with_editor.bind(item)
		)
		edit_btn.set_script(RunButton)
		edit_btn.init(item)

		var run_btn = buttons.simple(
			tr("Run"), 
			get_theme_icon("Play", "EditorIcons"),
			_on_run_with_editor.bind(item, "-g", "run", "Run", false)
		)
		run_btn.set_script(RunButton)
		run_btn.init(item)

		var bind_editor_btn = buttons.simple(
			tr("Bind Editor"), 
			get_theme_icon("GodotMonochrome", "EditorIcons"),
			_on_rebind_editor.bind(item)
		)
		bind_editor_btn.disabled = item.is_missing
		
		var manage_tags_btn = buttons.simple(
			tr("Manage Tags"), 
			get_theme_icon("Script", "EditorIcons"),
			func(): manage_tags_requested.emit()
		)
		manage_tags_btn.disabled = item.is_missing
		
		var remove_btn = buttons.simple(
			tr("Remove"), 
			get_theme_icon("Remove", "EditorIcons"),
			_on_remove
		)
		
		var view_command_btn = buttons.simple(
			tr("View Command"), 
			get_theme_icon("Window", "EditorIcons"),
			func(): 
				var command_viewer = get_tree().current_scene.get_node_or_null(
					"%CommandViewer"
				)
				if command_viewer:
					command_viewer.raise(
						_get_process_arguments(item, "-e"),
						_get_alternative_process_arguments(item, "-e")
					)
		)
		view_command_btn.disabled = not item.is_valid
		
#		var actions = []
#		if not item.is_missing:
#			actions.append(edit_btn)
#			actions.append(bind_editor_btn)
#		actions.append(remove_btn)
		return [edit_btn, run_btn, bind_editor_btn, manage_tags_btn, view_command_btn, remove_btn]
	
	_explore_button.pressed.connect(func():
		OS.shell_show_in_file_manager(ProjectSettings.globalize_path(item.path).get_base_dir())
	)
	_favorite_button.toggled.connect(func(is_favorite):
		item.favorite = is_favorite
		edited.emit()
	)
	double_clicked.connect(_on_edit_with_editor.bind(item))


func _fill_data(item):
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


func _set_features(features):
	var features_to_print = Array(features).filter(func(x): return _is_version(x) or x == "C#")
	if len(features_to_print) > 0:
		var str = ", ".join(features_to_print)
		_project_features.text = str
		_project_features.custom_minimum_size = Vector2(25 * 15, 10) * Config.EDSCALE
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
	
	vbox.add_spacer(false)
	
	title.text = ": " % tr("Editor")
	
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


func _on_edit_with_editor(item):
	_on_run_with_editor(item, "-e", "edit", "Edit", true)


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
	

func _run_with_editor(item, editor_flag, auto_close):
	var output = []
	var process_schema = _get_process_arguments(item, editor_flag)
	OS.create_process(process_schema.path, process_schema.args)
	Output.push_array(output)
	if auto_close:
		AutoClose.close_if_should()


func _get_process_arguments(item, editor_flag):
	if OS.has_feature("windows") or OS.has_feature("linux"):
		return {
			"path": ProjectSettings.globalize_path(item.editor_path),
			"args": [
				"--path",
				ProjectSettings.globalize_path(item.path).get_base_dir(),
				editor_flag
			]
		}
	elif OS.has_feature("macos"):
		return {
			"path": "open",
			"args": [
				ProjectSettings.globalize_path(item.editor_path),
				"-n",
				"--args",
				"--path",
				ProjectSettings.globalize_path(item.path).get_base_dir(),
				editor_flag
			]
		}


func _get_alternative_process_arguments(item, editor_flag):
	if not OS.has_feature("macos"):
		return null
	else:
		return {
			"path": ProjectSettings.globalize_path(item.editor_path).path_join("Contents/MacOS/Godot"),
			"args": [
#				"-n",
				"--path",
				ProjectSettings.globalize_path(item.path).get_base_dir(),
				editor_flag
			]
		}


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
	if _get_actions_callback:
		return _get_actions_callback.call()
	else:
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

