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
	
	_orphan_editors_explorer.init(editors, Config.VERSIONS_PATH)
	_orphan_editors_button.tooltip_text = "Check if there are some leaked Godot binaries on the filesystem that can be safely removed."
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


func _on_editors_list_item_removed(item_data: Editors.LocalEditor, remove_dir: bool) -> void:
	if remove_dir:
		var base_dir = ProjectSettings.globalize_path(item_data.path.get_base_dir())
		var versions_dir = ProjectSettings.globalize_path(Config.VERSIONS_PATH)
		if not OS.has_feature("linux"):
			base_dir = base_dir.to_lower()
			versions_dir = versions_dir.to_lower()
		if base_dir != versions_dir and base_dir.begins_with(versions_dir):
			dir.remove_recursive(base_dir)
		else:
			Output.push("skipping removing path {%s}" % base_dir)
	if _local_editors.has(item_data.path):
		_local_editors.erase(item_data.path)
		_local_editors.save()
	_sidebar.refresh_actions([])


func _on_editors_list_item_edited(item_data) -> void:
	_local_editors.save()
	_editors_list.sort_items()


func _on_editors_list_item_manage_tags_requested(item_data) -> void:
	var all_tags = Set.new()
	all_tags.append_array(_local_editors.get_all_tags())
	all_tags.append_array(Config.DEFAULT_EDITOR_TAGS)
	manage_tags_requested.emit(
		item_data.tags,
		all_tags.values(),
		func(new_tags):
			item_data.tags = new_tags
			item_data.emit_tags_edited()
			_on_editors_list_item_edited(item_data)
	)
