extends HBoxListItem

signal edited
signal removed(remove_dir: bool)
signal manage_tags_requested
signal tag_clicked(tag)


@export var _rename_dialog_scene: PackedScene

@onready var _path_label: Label = %PathLabel
@onready var _title_label: Label = %TitleLabel
@onready var _explore_button: Button = %ExploreButton
@onready var _favorite_button: TextureButton = %FavoriteButton
@onready var _tag_container: HBoxContainer = %TagContainer

var _get_actions_callback: Callable
var _tags = []
var _sort_data = {
	'ref': self
}


func _ready():
	super._ready()
	_tag_container.tag_clicked.connect(func(tag): tag_clicked.emit(tag))


func init(item):
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
	
	_sort_data.favorite = item.favorite
	_sort_data.name = item.name
	_sort_data.path = item.path
	_sort_data.tag_sort_string = "".join(item.tags)
	
	_get_actions_callback = func():
		var run_btn = buttons.simple(
			tr("Run"), 
			get_theme_icon("Play", "EditorIcons"),
			_on_run_editor.bind(item)
		)
		run_btn.disabled = not item.is_valid
		
		var rename_btn = buttons.simple(
			tr("Rename"), 
			get_theme_icon("Rename", "EditorIcons"),
			func(): _on_rename(item)
		)
		rename_btn.disabled = not item.is_valid
		
		var manage_tags_btn = buttons.simple(
			tr("Manage Tags"), 
			get_theme_icon("Script", "EditorIcons"),
			func(): manage_tags_requested.emit()
		)
		manage_tags_btn.disabled = not item.is_valid

		var view_command_btn = buttons.simple(
			tr("View Command"), 
			get_theme_icon("Window", "EditorIcons"),
			func(): 
				var command_viewer = get_tree().current_scene.get_node_or_null(
					"%CommandViewer"
				)
				if command_viewer:
					command_viewer.raise(
						_get_process_arguments(item),
						_get_alternative_process_arguments(item)
					)
		)
		view_command_btn.disabled = not item.is_valid

		return [
			run_btn,
			rename_btn,
			manage_tags_btn,
			view_command_btn,
			buttons.simple(
				tr("Remove"), 
				get_theme_icon("Remove", "EditorIcons"),
				func(): _on_remove(item)
			),
		]
	
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


func _on_run_editor(item):
	var output = []
	var process_schema = _get_process_arguments(item)
	OS.create_process(process_schema.path, process_schema.args)
#	Output.push_array(output)
	AutoClose.close_if_should()


func _get_process_arguments(item):
	if OS.has_feature("windows") or OS.has_feature("linux"):
		return {
			"path": ProjectSettings.globalize_path(item.path),
			"args": ["-p"] 
		}
	elif OS.has_feature("macos"):
		return {
			"path": "open",
			"args": [ProjectSettings.globalize_path(item.path), "-n"],
		}


func _get_alternative_process_arguments(item):
	if not OS.has_feature("macos"):
		return null
	else:
		return {
			"path": ProjectSettings.globalize_path(item.path).path_join("Contents/MacOS/Godot"),
			"args": [],
		}


func _on_rename(item):
	var dialog = _rename_dialog_scene.instantiate()
	add_child(dialog)
	dialog.popup_centered()
	dialog.init(item.name)
	dialog.editor_renamed.connect(func(new_name):
		item.name = new_name
		_title_label.text = item.name
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
