extends AcceptDialog


signal installed(editor_name, editor_exec_path)


@onready var _editor_name_edit: LineEdit = %EditorNameEdit
@onready var _select_exec_file_tree: Tree = %SelectExecFileTree


func init(editor_name, editor_exec_path):
	assert(editor_exec_path.ends_with("/"))
	
	_editor_name_edit.text = editor_name
	_setup_editor_select_tree(editor_exec_path)
	
	get_ok_button().disabled = true


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
			item.set_text(0, x)
			item.set_meta("full_path", editor_exec_path + x)
	
	create_tree_items.call(dirs, func(x): return x.ends_with(".app"))
	create_tree_items.call(files)
	
	_select_exec_file_tree.item_selected.connect(func(): 
		get_ok_button().disabled = false
	)


func _on_confirmed() -> void:
	# TODO validate data ???
	var selected_item = _select_exec_file_tree.get_selected()
	assert(selected_item)
	installed.emit(
		_editor_name_edit.text,
		selected_item.get_meta("full_path")
	)
	queue_free()


func _on_canceled() -> void:
	queue_free()
