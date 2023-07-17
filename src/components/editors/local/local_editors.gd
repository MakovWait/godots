extends HBoxContainer

signal editor_download_pressed
signal manage_tags_requested(item_tags, all_tags, on_confirm)

const Editors = preload("res://src/services/local_editors.gd")
const dir = preload("res://src/extensions/dir.gd")

@onready var _editors_list: VBoxContainer = $EditorsList
@onready var _sidebar: VBoxContainer = $ActionsSidebar
@onready var _download_button: Button = %DownloadButton
@onready var _orphan_editors_button: Button = %OrphanEditorsButton
@onready var _orphan_editors_explorer: ConfirmationDialog = $OrphanEditorExplorer
@onready var _import_button: Button = %ImportButton

var _local_editors = Editors.LocalEditors


func _ready() -> void:
	_download_button.icon = get_theme_icon("AssetLib", "EditorIcons")
	_orphan_editors_button.icon = get_theme_icon("Debug", "EditorIcons")
	_import_button.icon = get_theme_icon("Load", "EditorIcons")
	
	_import_button.pressed.connect(func(): import())
	_download_button.pressed.connect(func(): editor_download_pressed.emit())
	
	$EditorImport.imported.connect(func(editor_name, editor_path):
		add(editor_name, editor_path)
	)


func init(editors: Editors.LocalEditors):
	_local_editors = editors
	_editors_list.refresh(_local_editors.all())
	_editors_list.sort_items()
	
	_orphan_editors_explorer.init(editors, "user://versions")
	_orphan_editors_button.pressed.connect(func():
		_orphan_editors_explorer.before_popup()
		_orphan_editors_explorer.popup_centered_ratio(0.4)
	)


func add(editor_name, exec_path):
	if not _local_editors.has(exec_path):
		var editor = _local_editors.add(editor_name, exec_path)
		_local_editors.save()
		_editors_list.add(editor)


func import(editor_name="", editor_path=""):
	if $EditorImport.visible: 
		return
	$EditorImport.init(editor_name, editor_path)
	$EditorImport.popup_centered()


func _on_editors_list_item_selected(item) -> void:
	_sidebar.refresh_actions(item.get_actions())


func _on_editors_list_item_removed(item_data: Editors.LocalEditor) -> void:
#	dir.remove_recursive(item_data.path.get_base_dir())
	if _local_editors.has(item_data.path):
		_local_editors.erase(item_data.path)
		_local_editors.save()
	_sidebar.refresh_actions([])


func _on_editors_list_item_edited(item_data) -> void:
	_local_editors.save()
	_editors_list.sort_items()


func _on_editors_list_item_manage_tags_requested(item_data) -> void:
	manage_tags_requested.emit(
		item_data.tags,
		_local_editors.get_all_tags(),
		func(new_tags):
			item_data.tags = new_tags
			item_data.emit_tags_edited()
			_on_editors_list_item_edited(item_data)
	)
