class_name CloneProjectDialog
extends "res://src/components/projects/install_project_dialog/install_project_dialog.gd"


signal cloned(path: String)

@onready var _repository_edit: LineEdit = %RepositoryEdit
@onready var _clone_failed_dialog: AcceptDialog = $CloneFailedDialog

var _cloning_window := CloningWindow.new()


func _ready() -> void:
	super._ready()
	_cloning_window.visible = false
	add_child(_cloning_window)
	
	dialog_hide_on_ok = false
	_repository_edit.text_changed.connect(func(new_text: String) -> void:
		_project_name_edit.text = new_text.get_file().replace(".git", "")
		_update_project_dir()
	)
	_successfully_confirmed.connect(func() -> void:
		var project_name := _project_name_edit.text.strip_edges()
		var project_path := ProjectSettings.globalize_path(
			_project_path_line_edit.text.strip_edges()
		)
		var origin_repository := _repository_edit.text.strip_edges()
		
		_cloning_window.popup_centered()
		
#		_do_clone(origin_repository, project_path)
		var cloning_thread := Thread.new()
		cloning_thread.start(func() -> void:
			_do_clone(origin_repository, project_path)
		)
	)


func _do_clone(origin_repository: String, project_path: String) -> void:
	var output := []
	var err := OS.execute(
		"git",
		[
			"clone", 
			origin_repository, 
			project_path
		],
		output,
		true
	)
	call_thread_safe("_emit_cloned", err, output, project_path)


func _emit_cloned(err: Error, output: Array, path: String) -> void:
	Output.push("Git executed with error code: %s" % err)
	Output.push_array(output)
	_cloning_window.hide()
	
	if err != OK:
		_spawn_clone_alert(err)
		_validate()
		return
	
	var possible_project_files := utils.find_project_godot_files(path)
	if len(possible_project_files) == 0:
		_spawn_unable_to_find_project_godot_alert()
		_validate()
		return
	
	hide()
	cloned.emit(possible_project_files[0].path)


func _on_raise(args: Variant = null) -> void:
	_repository_edit.clear()
	_repository_edit.grab_focus()


func _spawn_clone_alert(err: Error) -> void:
	_clone_failed_dialog.dialog_text = tr('Failed to clone. Error code: %s' % err)
	_clone_failed_dialog.popup_centered()


func _spawn_unable_to_find_project_godot_alert() -> void:
	_clone_failed_dialog.dialog_text = tr('Unable to find project.godot file.')
	_clone_failed_dialog.popup_centered()


class CloningWindow extends Window:
	var bg: Panel = Panel.new()
#	var base_control: Control = PanelContainer.new()
#
	func _init() -> void:
		add_child(bg)
#		add_child(base_control)

	func _notification(what: int) -> void:
		if NOTIFICATION_WM_SIZE_CHANGED == what:
			bg.set_size(size)
			bg.set_position(Vector2.ZERO)
			
#			base_control.set_size(size)
#			base_control.set_position(Vector2.ZERO)

	func _ready() -> void:
		transient = true
		exclusive = true
		unresizable = true
		
		min_size = Vector2i(256, 0) * Config.EDSCALE
		size = min_size
		title = tr("Cloning...")

#		var vb = VBoxContainer.new()
#		vb.alignment = BoxContainer.ALIGNMENT_CENTER
#		var label = Label.new()
#		label.text = tr("Cloning...")
#		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
#		vb.add_child(label)
#		base_control.add_child(vb)
