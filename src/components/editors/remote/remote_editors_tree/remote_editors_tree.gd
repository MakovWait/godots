extends VBoxContainer


signal _loadings_number_changed(value)

const uuid = preload("res://addons/uuid.gd")

@onready var _tree: Tree = %Tree
@onready var _check_box_container: HFlowContainer = %CheckBoxContainer

var _refresh_button: Button
var _remote_assets: RemoteEditorsTreeDataSource.RemoteAssets

var _src: RemoteEditorsTreeDataSource.I
var _i_remote_tree: RemoteEditorsTreeDataSource.RemoteTree
var _root_loaded = false
var _row_filters: Array[RowFilter] = [NotRelatedFilter.new()]
var _current_loadings_number = 0:
	set(value): 
		_current_loadings_number = value
		_loadings_number_changed.emit(value)
var _remote_editors_checkbox_checked = Cache.smart_section(
	Cache.section_of(self) + ".checkbox_checked", true
)


func post_ready(refresh_button: Button):
	_refresh_button = refresh_button
	
	_setup_tree()
	_setup_checkboxes()

	_refresh_button.pressed.connect(func():
		_refresh()
	)

	_loadings_number_changed.connect(func(value):
		_refresh_button.disabled = value != 0
	)


func _ready():
	visibility_changed.connect(_on_visibility_changed)


func set_data_source(src: RemoteEditorsTreeDataSource.I):
	if _src != null:
		_src.cleanup(_tree)
	_src = src
	_src.setup(_tree)
	_refresh()


func _refresh():
	for c in _tree.get_root().get_children():
		c.free()
	_expand(_delegate_of(_tree.get_root()))


func _setup_checkboxes():
	%CheckBoxPanelContainer.add_theme_stylebox_override("panel", get_theme_stylebox("panel", "Tree"))
	
	var checkbox = func(text, filter, button_pressed=false):
		var box = CheckBox.new()
		box.text = text
		box.button_pressed = button_pressed
		if button_pressed:
			_row_filters.append(filter)
		box.toggled.connect(func(pressed):
			if pressed: 
				_row_filters.append(filter)
			else:
				var idx = _row_filters.find(filter)
				_row_filters.remove_at(idx)
			_remote_editors_checkbox_checked.set_value(text, pressed)
			_update_whole_tree_visibility(_delegate_of(_tree.get_root()))
		)
		return box

	var inverted_checkbox = func(text, filter, button_pressed=false):
		var box = CheckBox.new()
		box.text = text
		box.button_pressed = button_pressed
		if not button_pressed:
			_row_filters.append(filter)
		box.toggled.connect(func(pressed):
			if pressed: 
				var idx = _row_filters.find(filter)
				if idx >= 0:
					_row_filters.remove_at(idx)
			else:
				_row_filters.append(filter)
			_remote_editors_checkbox_checked.set_value(text, pressed)
			_update_whole_tree_visibility(_delegate_of(_tree.get_root()))
		)
		return box

	var contains_any = func(words):
		return func(row: RemoteEditorsTreeDataSource.FilterTarget): 
			return words.any(func(x): return row.get_name().to_lower().contains(x.to_lower()))
	
	var _not = func(original):
		return func(row): return not original.call(row)
	
	_check_box_container.add_child(
		inverted_checkbox.call(
			tr("mono"), 
			RowFilter.new(contains_any.call(["mono"])),
			_remote_editors_checkbox_checked.get_value("mono", true)
		)
	)
	
	_check_box_container.add_child(
		inverted_checkbox.call(
			tr("unstable"), 
			RowFilter.new(contains_any.call(["rc", "beta", "alpha", "dev", "fixup"])),
			_remote_editors_checkbox_checked.get_value("unstable", false)
		)
	)
	
	_check_box_container.add_child(
		inverted_checkbox.call(
			tr("any platform"), 
			RowFilter.new(func(row): 
				return row.is_file() and row.is_for_different_platform(_src.get_platform_suffixes())),
			_remote_editors_checkbox_checked.get_value("any platform", false)
		)
	)

	if not OS.has_feature("macos"):
		var bit
		var opposite 
		if OS.has_feature("32"):
			bit = "32"
			opposite = "64"
		elif OS.has_feature("64"):
			bit = "64"
			opposite = "32"
		if bit:
			_check_box_container.add_child(
				checkbox.call(
					"%s-bit" % bit, 
					RowFilter.new(contains_any.call([opposite])),
					_remote_editors_checkbox_checked.get_value("%s-bit" % bit, true)
				)
			)

	_check_box_container.add_child(
		inverted_checkbox.call(
			tr("4.x"), 
			RowFilter.new(func(row: RemoteEditorsTreeDataSource.FilterTarget): 
				return row.is_possible_version_folder() and row.get_name().begins_with("4")),
			_remote_editors_checkbox_checked.get_value("4.x", true)
		)
	)

	_check_box_container.add_child(
		inverted_checkbox.call(
			tr("3.x"), 
			RowFilter.new(func(row: RemoteEditorsTreeDataSource.FilterTarget): 
				return row.is_possible_version_folder() and row.get_name().begins_with("3")),
			_remote_editors_checkbox_checked.get_value("3.x", true)
		)
	)

	_check_box_container.add_child(
		inverted_checkbox.call(
			tr("x.x"), 
			RowFilter.new(func(row: RemoteEditorsTreeDataSource.FilterTarget): 
				return row.is_possible_version_folder() and not (row.get_name().begins_with("4") or row.get_name().begins_with("3"))),
			_remote_editors_checkbox_checked.get_value("x.x", false)
		)
	)


func _delegate_of(item: TreeItem) -> RemoteEditorsTreeDataSource.Item:
	return _src.to_remote_item(item)


func _setup_tree():
	_i_remote_tree = RemoteEditorsTreeDataSource.RemoteTree.new(_tree, self)
	
	_tree.item_collapsed.connect(
		func(x: TreeItem): 
			var expanded = not x.collapsed
			var delegate = _delegate_of(x)
			var not_loaded_yet = not delegate.is_loaded()
			if expanded and not_loaded_yet:
				_expand.call_deferred(delegate)
#				_expand(delegate)
	)

	_tree.button_clicked.connect(func(item, col, id, mouse):
		var delegate = _delegate_of(item)
		delegate.handle_button_clicked(col, id, mouse)
	)


func _expand(remote_tree_item: RemoteEditorsTreeDataSource.Item):
	_current_loadings_number += 1
	await remote_tree_item.async_expand(_i_remote_tree)
	_update_whole_tree_visibility(remote_tree_item)
	_current_loadings_number -= 1


func _update_whole_tree_visibility(from: RemoteEditorsTreeDataSource.Item):
	from.update_visibility(_row_filters)
	for child in from.get_children():
		_update_whole_tree_visibility(child)


func _on_visibility_changed() -> void:
	if is_visible_in_tree() and not _root_loaded:
		_expand(_delegate_of(_tree.get_root()))
		_root_loaded = true


class RowFilter:
	var _delegate
	
	func _init(delegate):
		_delegate = delegate
	
	func test(row: RemoteEditorsTreeDataSource.FilterTarget) -> bool:
		return _delegate.call(row)


class SimpleContainsFilter extends RowFilter:
	func _init(what: String):
		super._init(
			func(row: RemoteEditorsTreeDataSource.FilterTarget): 
				return row.get_name().to_lower().contains(what)
		)


class NotRelatedFilter extends RowFilter:
	func _init():
		super._init(
			func(row: RemoteEditorsTreeDataSource.FilterTarget): 
				return ["media", "patreon", "testing", "toolchains"].any(
					func(x): return row.get_name() == x
				)
		)
