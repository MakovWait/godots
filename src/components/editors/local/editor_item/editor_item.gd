extends HBoxListItem

#signal edited(data: A)
signal removed

const buttons = preload("res://src/extensions/buttons.gd")


@onready var _path_label: Label = %PathLabel
@onready var _title_label: Label = %TitleLabel
@onready var _explore_button: Button = %ExploreButton

var _get_actions_callback: Callable


func init(item):
	_title_label.text = item.name
	_path_label.text = item.path
	
	_get_actions_callback = func():
		return [
			_make_button(
				"Run", 
				get_theme_icon("Play", "EditorIcons"),
				func():
					# TODO handle all OS
					OS.execute("open", [ProjectSettings.globalize_path(item.path)]),
			),
			_make_button(
				"Rename", 
				get_theme_icon("Edit", "EditorIcons"),
				func(): pass
			),
			_make_button(
				"Remove", 
				get_theme_icon("Remove", "EditorIcons"),
				_on_remove
			)
		]
	
	_explore_button.pressed.connect(func():
		OS.shell_show_in_file_manager(ProjectSettings.globalize_path(item.path).get_base_dir())
	)


func _on_remove():
	var confirmation_dialog = ConfirmationDialogAutoFree.new()
	confirmation_dialog.ok_button_text = "Remove"
	confirmation_dialog.dialog_text = "Are you sure to remove the editor from the file system?"
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
		'path': _path_label.text
	})
