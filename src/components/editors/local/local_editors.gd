extends HBoxContainer

signal editor_download_pressed

const Editors = preload("res://src/services/local_editors.gd")
const dir = preload("res://src/extensions/dir.gd")

@onready var _editors_list: VBoxContainer = $EditorsList
@onready var _sidebar: VBoxContainer = $ActionsSidebar
@onready var _download_button: Button = %DownloadButton
@onready var _orphan_editors_button: Button = %OrphanEditorsButton
@onready var _orphan_editors_explorer: ConfirmationDialog = $OrphanEditorExplorer

var _local_editors = Editors.LocalEditors


func _ready() -> void:
	_download_button.icon = get_theme_icon("AssetLib", "EditorIcons")
	_orphan_editors_button.icon = get_theme_icon("Debug", "EditorIcons")
	_download_button.pressed.connect(func(): editor_download_pressed.emit())


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


func _on_editors_list_item_selected(item) -> void:
	_sidebar.refresh_actions(item.get_actions())


func _on_editors_list_item_removed(item_data: Editors.LocalEditor) -> void:
	dir.remove_recursive(item_data.path.get_base_dir())
	if _local_editors.has(item_data.path):
		_local_editors.erase(item_data.path)
		_local_editors.save()
	_sidebar.refresh_actions([])


func _on_editors_list_item_edited(item_data) -> void:
	_local_editors.save()
	_editors_list.sort_items()
