extends AcceptDialog


signal installed(editor_name, editor_exec_path)


@onready var _editor_name_edit: LineEdit = %EditorNameEdit
@onready var _select_exec_file_tree: Tree = %SelectExecFileTree
@onready var _file_dialog = $FileDialog
@onready var _browse_exec_file_button = %BrowseExecFileButton
@onready var _exec_path_edit = %ExecPathEdit


var _selected_file_source


func _ready():
	min_size = Vector2(300, 0) * Config.EDSCALE
	if OS.has_feature("macos"):
		_select_exec_file_tree.custom_minimum_size = Vector2(0, 300) * Config.EDSCALE
	_browse_exec_file_button.pressed.connect(func():
		_file_dialog.popup_centered_ratio(0.5)
	)
	_browse_exec_file_button.icon = get_theme_icon("Load", "EditorIcons")


func init(editor_name, editor_exec_path):
	assert(editor_exec_path.ends_with("/"))
	Output.push("Installing editor: %s" % editor_exec_path)
	_editor_name_edit.text = editor_name
	if OS.has_feature("macos"):
		_select_exec_file_tree.show()
		_setup_editor_select_tree(editor_exec_path)
	else:
		_setup_editor_select_dialog(editor_exec_path)
		_browse_exec_file_button.show()
		_exec_path_edit.show()
	
	get_ok_button().disabled = true


func _setup_editor_select_dialog(editor_exec_path):
	var selected_file = {}
	if OS.has_feature("windows"):
		_file_dialog.filters = ["*.exe"]
	_file_dialog.root_subfolder = editor_exec_path
	_file_dialog.file_selected.connect(func(path):
		selected_file['value'] = path
		_exec_path_edit.text = path
		get_ok_button().disabled = false
	)
	_selected_file_source = func(): return selected_file['value']


func _setup_editor_select_tree(editor_exec_path):
	var root = _select_exec_file_tree.create_item()
	var dir = DirAccess.open(editor_exec_path)
	var dirs = dir.get_directories()
	var files = dir.get_files()
	
	var create_tree_items = func(source, filter=null):
		for x in source:
			if filter and not filter.call(x):
				continue
			var item = _select_exec_file_tree.create_item(root)
			item.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
			item.set_text(0, x)
			item.set_editable(0, true)
			item.set_meta("full_path", editor_exec_path + x)
	
	create_tree_items.call(dirs, func(x): return x.ends_with(".app"))
	
	_select_exec_file_tree.item_selected.connect(func(): 
		get_ok_button().disabled = false
	)
	_selected_file_source = func(): 
		var selected_item = _select_exec_file_tree.get_selected()
		assert(selected_item)
		return selected_item.get_meta("full_path")


func _on_confirmed() -> void:
	# TODO validate data ???
	installed.emit(
		_editor_name_edit.text,
		_selected_file_source.call()
	)
	queue_free()


func _on_canceled() -> void:
	queue_free()
