extends HBoxListItem

signal edited
signal removed
signal manage_tags_requested

const buttons = preload("res://src/extensions/buttons.gd")
const projects_ns = preload("res://src/services/projects.gd")

@export var _tag_scene: PackedScene

@onready var _path_label: Label = %PathLabel
@onready var _title_label: Label = %TitleLabel
@onready var _explore_button: Button = %ExploreButton
@onready var _favorite_button: TextureButton = $Favorite/FavoriteButton
@onready var _icon: TextureRect = $Icon
@onready var _editor_path_label: Label = %EditorPathLabel
@onready var _editor_button: Button = %EditorButton
@onready var _project_warning: TextureRect = %ProjectWarning
@onready var _tag_container: HBoxContainer = %TagContainer

var _get_actions_callback: Callable


func _ready() -> void:
	super._ready()
	_editor_button.icon = get_theme_icon("GodotMonochrome", "EditorIcons")
	_project_warning.texture = get_theme_icon("NodeWarning", "EditorIcons")
	_project_warning.tooltip_text = "Editor is missing"
	_title_label.custom_minimum_size = Vector2(128, 0) * Config.EDSCALE


func init(item: projects_ns.Project):
	item.load()
	
	if not item.is_loaded:
		await item.loaded
	
	if item.is_missing:
		_explore_button.icon = get_theme_icon("FileBroken", "EditorIcons")
		modulate = Color(1, 1, 1, 0.498)
	
	item.internals_changed.connect(func():
		_title_label.text = item.name
		_editor_path_label.text = item.editor_name
		_project_warning.visible = item.has_invalid_editor
		_setup_tags(item)
	)

	_project_warning.visible = item.has_invalid_editor
	_favorite_button.button_pressed = item.favorite
	_title_label.text = item.name
	_editor_path_label.text = item.editor_name
	_path_label.text = item.path
	_icon.texture = item.icon
	_setup_tags(item)
	
	_get_actions_callback = func():
		var run_btn = buttons.simple(
			"Edit", 
			get_theme_icon("Edit", "EditorIcons"),
			_on_run_with_editor.bind(item)
		)
		run_btn.set_script(RunButton)
		run_btn.init(item)
		
		var bind_editor_btn = buttons.simple(
			"Bind Editor", 
			get_theme_icon("GodotMonochrome", "EditorIcons"),
			_on_rebind_editor.bind(item)
		)
		bind_editor_btn.disabled = item.is_missing
		
		var manage_tags_btn = buttons.simple(
			"Manage Tags", 
			get_theme_icon("Script", "EditorIcons"),
			func(): manage_tags_requested.emit()
		)
		manage_tags_btn.disabled = item.is_missing
		
		var remove_btn = buttons.simple(
			"Remove", 
			get_theme_icon("Remove", "EditorIcons"),
			_on_remove
		)
		
#		var actions = []
#		if not item.is_missing:
#			actions.append(run_btn)
#			actions.append(bind_editor_btn)
#		actions.append(remove_btn)
		return [run_btn, bind_editor_btn, manage_tags_btn, remove_btn]
	
	_explore_button.pressed.connect(func():
		OS.shell_show_in_file_manager(ProjectSettings.globalize_path(item.path).get_base_dir())
	)
	_favorite_button.toggled.connect(func(is_favorite):
		item.favorite = is_favorite
		edited.emit()
	)


func _setup_tags(item):
	for child in _tag_container.get_children():
		child.queue_free()
	for tag in item.tags:
		var tag_control = _tag_scene.instantiate()
		_tag_container.add_child(tag_control)
		tag_control.init(tag)


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
	
	title.text = "Editor: "
	
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


func _on_run_with_editor(item):
	var output = []
	if OS.has_feature("windows") or OS.has_feature("linux"):
		OS.execute(
			ProjectSettings.globalize_path(item.editor_path),
			[
				"--path",
				ProjectSettings.globalize_path(item.path).get_base_dir(),
				"-e"
			], output, true
		)
	elif OS.has_feature("macos"):
		OS.execute(
			"open", 
			[
				ProjectSettings.globalize_path(item.editor_path),
				"--args",
				"--path",
				ProjectSettings.globalize_path(item.path).get_base_dir(),
				"-e"
			], output, true
		)
	Output.push_array(output)


func _on_remove():
	var confirmation_dialog = ConfirmationDialogAutoFree.new()
	confirmation_dialog.ok_button_text = "Remove"
	confirmation_dialog.dialog_text = "Are you sure to remove the project from the list?"
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


class RunButton extends Button:
	func init(item):
		disabled = item.has_invalid_editor or item.is_missing
		item.internals_changed.connect(func():
			disabled = item.has_invalid_editor or item.is_missing
		)

