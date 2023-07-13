extends HBoxListItem

signal edited
signal removed

const buttons = preload("res://src/extensions/buttons.gd")

@export var _rename_dialog_scene: PackedScene

@onready var _path_label: Label = %PathLabel
@onready var _title_label: Label = %TitleLabel
@onready var _explore_button: Button = %ExploreButton
@onready var _favorite_button: TextureButton = %FavoriteButton

var _get_actions_callback: Callable


func init(item):
	_title_label.text = item.name
	_path_label.text = item.path
	_favorite_button.button_pressed = item.favorite
	
	_get_actions_callback = func():
		return [
			buttons.simple(
				"Run", 
				get_theme_icon("Play", "EditorIcons"),
				func():
					# TODO handle all OS
					OS.execute("open", [ProjectSettings.globalize_path(item.path)]),
			),
			buttons.simple(
				"Rename", 
				get_theme_icon("Rename", "EditorIcons"),
				func(): _on_rename(item)
			),
			buttons.simple(
				"Remove", 
				get_theme_icon("Remove", "EditorIcons"),
				_on_remove
			)
		]
	
	_explore_button.pressed.connect(func():
		OS.shell_show_in_file_manager(ProjectSettings.globalize_path(item.path).get_base_dir())
	)
	_favorite_button.toggled.connect(func(is_favorite):
		item.favorite = is_favorite
		edited.emit()
	)


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


func get_sort_data():
	return {
		'ref': self,
		'favorite': _favorite_button.button_pressed,
		'name': _title_label.text
	}
