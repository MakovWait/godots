class_name LocalEditorsControl
extends HBoxContainer

signal editor_download_pressed
signal manage_tags_requested(item_tags: Array, all_tags: Array, on_confirm: Callable)

@onready var _editors_list: EditorsVBoxList = %EditorsList
@onready var _sidebar: ActionsSidebarControl = %ActionsSidebar
@onready var _orphan_editors_explorer: OrphanEditorExplorerWindow = %OrphanEditorExplorer
@onready var _scan_dialog := %ScanDialog as ScanFileDialog


var _local_editors: LocalEditors.List
var _remove_missing_action: Action.Self


func _ready() -> void:
	(%EditorImport as EditorImportDialog).imported.connect(func(editor_name: String, editor_path: String) -> void:
		add(editor_name, editor_path)
	)

	_scan_dialog.dir_to_scan_selected.connect(func(dir_to_scan: String) -> void:
		_scan_editors(dir_to_scan)
	)
	
	var remove_missing_popup := RemoveMissingDialog.new(_remove_missing)
	add_child(remove_missing_popup)
	
	var actions := Action.List.new([
		Action.from_dict({
			"key": "import",
			"icon": Action.IconTheme.new(self, "Load", "EditorIcons"),
			"act": import,
			"label": tr("Import"),
		}),
		Action.from_dict({
			"key": "download",
			"icon": Action.IconTheme.new(self, "AssetLib", "EditorIcons"),
			"act": func() -> void: editor_download_pressed.emit(),
			"label": tr("Download"),
		}),
		Action.from_dict({
			"key": "orphan",
			"icon": Action.IconTheme.new(self, "Debug", "EditorIcons"),
			"act": func() -> void:
				_orphan_editors_explorer.before_popup()
				_orphan_editors_explorer.popup_centered_ratio(0.4)
				pass,\
			"label": tr("Orphan Editors Explorer"),
			"tooltip": tr("Check if there are some leaked Godot binaries on the filesystem that can be safely removed. For advanced users.")
		}),
		Action.from_dict({
			"key": "scan",
			"icon": Action.IconTheme.new(self, "Search", "EditorIcons"),
			"act": func() -> void:
				_scan_dialog.current_dir = ProjectSettings.globalize_path(
					Config.VERSIONS_PATH.ret() as String
				)
				_scan_dialog.popup_centered_ratio(0.5)
				pass,\
			"label": tr("Scan"),
		}),
		Action.from_dict({
			"key": "refresh",
			"icon": Action.IconTheme.new(self, "Reload", "EditorIcons"),
			"act": _refresh,\
			"label": tr("Refresh List"),
		}),
		Action.from_dict({
			"label": tr("Remove Missing"),
			"key": "remove-missing",
			"icon": Action.IconTheme.new(self, "Clear", "EditorIcons"),
			"act": func() -> void: remove_missing_popup.popup_centered()
		}),
	])
	
	_remove_missing_action = actions.by_key("remove-missing")

	var editor_actions := TabActions.Menu.new(
		actions.sub_list([
			'import',
			'download',
			'scan',
		]).all(), 
		TabActions.Settings.new(
			Cache.section_of(self), 
			[
				'import',
				'download',
				'scan',
			]
		)
	)
	editor_actions.add_controls_to_node(%EditorsList/HBoxContainer/TabActions as Control)
	editor_actions.icon = get_theme_icon("GuiTabMenuHl", "EditorIcons")
	
	%EditorsList/HBoxContainer.add_child(_remove_missing_action.to_btn().make_flat(true).show_text(false))
	%EditorsList/HBoxContainer.add_child(actions.by_key('orphan').to_btn().make_flat(true).show_text(false))
	%EditorsList/HBoxContainer.add_child(actions.by_key('refresh').to_btn().make_flat(true).show_text(false))
	%EditorsList/HBoxContainer.add_child(editor_actions)


func init(editors: LocalEditors.List) -> void:
	_local_editors = editors
	_editors_list.refresh(_local_editors.all())
	_editors_list.sort_items()
	
	_orphan_editors_explorer.init(editors, Config.VERSIONS_PATH.ret() as String)
	_update_remove_missing_disabled()


func add(editor_name: String, exec_path: String) -> void:
	if not _local_editors.has(exec_path):
		var editor := _local_editors.add(editor_name, exec_path)
		_local_editors.save()
		_editors_list.add(editor)


func import(editor_name:="", editor_path:="") -> void:
	var editor_import := %EditorImport as EditorImportDialog
	if editor_import.visible: 
		return
	editor_import.init(editor_name, editor_path)
	editor_import.popup_centered()


func _refresh() -> void:
	_local_editors.load()
	_editors_list.refresh(_local_editors.all())
	_editors_list.sort_items()
	_update_remove_missing_disabled()


func _remove_missing() -> void:
	for e: LocalEditors.Item in _local_editors.all().filter(func(x: LocalEditors.Item) -> bool: return not x.is_valid):
		_local_editors.erase(e.path)
	_sidebar.refresh_actions([])
	_local_editors.save()
	_editors_list.refresh(_local_editors.all())
	_editors_list.sort_items()
	_update_remove_missing_disabled()


func _scan_editors(dir_to_scan: String) -> void:
	var filter: Callable
	if OS.has_feature("windows"):
		filter = func(x: edir.DirListResult) -> bool:
			var evidences := [
				x.is_file and x.extension == "exe",
				x.file.to_lower().contains("godot_v"),
				not x.file.to_lower().contains("console"),
			]
			return evidences.all(func(is_true: bool) -> bool: return is_true)
	elif OS.has_feature("macos"):
		filter = func(x: edir.DirListResult) -> bool:
			var evidences := [
				x.is_dir and x.extension == "app",
				x.file.to_lower().contains("godot")
			]
			return evidences.all(func(is_true: bool) -> bool: return is_true)
	elif OS.has_feature("linux"):
		filter = func(x: edir.DirListResult) -> bool:
			var evidences := [
				x.is_file and (
					x.extension.contains("32") or x.extension.contains("64")
				),
				x.file.to_lower().contains("godot_v")
			]
			return evidences.all(func(is_true: bool) -> bool: return is_true)

	var editors_exec := edir.list_recursive(
		ProjectSettings.globalize_path(dir_to_scan), 
		false,
		filter,
		(func(x: String) -> bool: 
			return not x.get_file().begins_with("."))
	)
	for editor_exec in editors_exec:
		var editor_exec_path := editor_exec.path
		if _local_editors.has(editor_exec_path):
			continue
		var editor := _local_editors.add(
			utils.guess_editor_name(editor_exec.file),
			editor_exec_path
		)
		_editors_list.add(editor)
	_local_editors.save()


func _update_remove_missing_disabled() -> void:
	_remove_missing_action.disable(
		len(_local_editors.all().filter(func(x: LocalEditors.Item) -> bool: return not x.is_valid)) == 0
	)


func _on_editors_list_item_selected(item: EditorListItemControl) -> void:
	_sidebar.refresh_actions(item.get_actions())


func _on_editors_list_item_removed(item_data: LocalEditors.Item, remove_dir: bool) -> void:
	if remove_dir:
		var base_dir := ProjectSettings.globalize_path(item_data.path.get_base_dir())
		var versions_dir := ProjectSettings.globalize_path(Config.VERSIONS_PATH.ret() as String)
		if not OS.has_feature("linux"):
			base_dir = base_dir.to_lower()
			versions_dir = versions_dir.to_lower()
		if base_dir != versions_dir and base_dir.begins_with(versions_dir):
			edir.remove_recursive(base_dir)
		else:
			Output.push("skipping removing path {%s}" % base_dir)
	if _local_editors.has(item_data.path):
		_local_editors.erase(item_data.path)
		_local_editors.save()
	_sidebar.refresh_actions([])
	_update_remove_missing_disabled()


func _on_editors_list_item_edited(item_data: Variant) -> void:
	_local_editors.save()
	_editors_list.sort_items()


func _on_editors_list_item_manage_tags_requested(item_data: LocalEditors.Item) -> void:
	var all_tags := Set.new()
	all_tags.append_array(_local_editors.get_all_tags())
	all_tags.append_array(Config.DEFAULT_EDITOR_TAGS.ret() as Array)
	manage_tags_requested.emit(
		item_data.tags,
		all_tags.values(),
		func(new_tags: Array) -> void:
			item_data.tags = new_tags
			item_data.emit_tags_edited()
			_on_editors_list_item_edited(item_data)
	)
