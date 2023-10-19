extends AcceptDialog


signal installed(editor_name, editor_exec_path)


@onready var _editor_name_edit: LineEdit = %EditorNameEdit
@onready var _select_exec_file_tree: Tree = %SelectExecFileTree
@onready var _file_dialog = $FileDialog
@onready var _show_all_check_box = %ShowAllCheckBox

var _dir_content = [] as Array[edir.DirListResult]
var _show_all: bool:
	get: return _show_all_check_box.button_pressed


func _ready():
	_select_exec_file_tree.custom_minimum_size = Vector2(350, 150) * Config.EDSCALE
	_select_exec_file_tree.select_mode = Tree.SELECT_SINGLE
	_select_exec_file_tree.item_selected.connect(func():
		var root = _select_exec_file_tree.get_root()
		var selected = _select_exec_file_tree.get_selected()
		if root:
			for c in root.get_children():
				if c == selected:
					continue
				c.set_checked(0, false)
	)
	_show_all_check_box.toggled.connect(func(_a):
		_setup_editor_select_tree()
	)


func init(editor_name, editor_exec_path):
	assert(editor_exec_path.ends_with("/"))
	Output.push("Installing editor: %s" % editor_exec_path)
	_dir_content = edir.list_recursive(editor_exec_path)
	_editor_name_edit.text = editor_name
	_select_exec_file_tree.show()
	_setup_editor_select_tree()


func _setup_editor_select_tree():
	_select_exec_file_tree.clear()
	var root = _select_exec_file_tree.create_item()
	
	var create_tree_items = func(source, filter=null, should_be_selected=null):
		var selected = false
		for x in source:
			if filter and not filter.call(x):
				continue
			var item = _select_exec_file_tree.create_item(root)
			item.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
			item.set_text(0, x.file)
			item.set_editable(0, true)
			item.set_meta("full_path", x.path)
			if not selected and should_be_selected != null:
				if should_be_selected.call(x):
					selected = true
					item.set_checked(0, true)
					item.select(0)

	var filter
	var should_be_selected
	if OS.has_feature("macos"):
		filter = func(x: edir.DirListResult):
			return x.is_dir and x.extension == "app"
		should_be_selected = func(x: edir.DirListResult):
			return x.is_dir and x.extension == "app"
	if OS.has_feature("windows"):
		filter = func(x: edir.DirListResult):
			return x.is_file and x.extension == "exe"
		should_be_selected = func(x: edir.DirListResult):
			return x.is_file and x.extension == "exe" and not x.file.contains("console")
	if OS.has_feature("linux"):
		filter = func(x: edir.DirListResult):
			return x.is_file and (
				x.extension.contains("32") or x.extension.contains("64")
			)
		should_be_selected = func(x: edir.DirListResult):
			return x.is_file and (
				x.extension.contains("32") or x.extension.contains("64")
			)
	
	create_tree_items.call(_dir_content, filter, should_be_selected)


func _process(delta):
	var ok_disabled = true
	var selected = _select_exec_file_tree.get_selected()
	if selected and selected.is_checked(0):
		ok_disabled = false
	get_ok_button().disabled = ok_disabled


func _on_confirmed() -> void:
	var selected_item = _select_exec_file_tree.get_selected()
	if not (selected_item and selected_item.is_checked(0)):
		return
	var path = selected_item.get_meta("full_path")
	# TODO validate data ???
	installed.emit(_editor_name_edit.text, path)
	queue_free()


func _on_canceled() -> void:
	queue_free()
