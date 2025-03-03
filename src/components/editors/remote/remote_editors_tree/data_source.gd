class_name RemoteEditorsTreeDataSource


class I:
	func setup(tree: Tree) -> void:
		return utils.not_implemeted()
	
	func cleanup(tree: Tree) -> void:
		return utils.not_implemeted()
	
	#TODO type
	func get_platform_suffixes() -> Array:
		return utils.not_implemeted()
	
	func to_remote_item(item: TreeItem) -> Item:
		return utils.not_implemeted()


# TODO looks bad
class RemoteAssets:
	func download(url: String, file_name: String) -> void:
		pass


class RemoteAssetsCallable extends RemoteAssets:
	var _callable: Callable
	
	func _init(callable: Callable) -> void:
		_callable = callable
	
	func download(url: String, file_name: String) -> void:
		_callable.call(url, file_name)


class FilterTarget:
	func is_possible_version_folder() -> bool:
		return false
	
	func is_file() -> bool:
		return false
	
	func is_for_different_platform(platform_suffixes: Array) -> bool:
		return false
	
	func get_name() -> String:
		return ''


class RemoteTree:
	var _tree: Tree
	var _theme_source: Control
	
	var theme_source: Control:
		get: return _theme_source
	
	func _init(tree: Tree, theme_source: Control) -> void:
		_tree = tree
		_theme_source = theme_source

	func create_item(parent: TreeItem) -> TreeItem:
		var result := _tree.create_item(parent)
		return result
	
	func free_loading_placeholder(tree_item: TreeItem) -> void:
		if tree_item.has_meta("loading_placeholder"):
			(tree_item.get_meta("loading_placeholder") as Object).free()
	
	func set_as_folder(tree_item: TreeItem) -> void:
			tree_item.set_icon(0, _theme_source.get_theme_icon("Folder", "EditorIcons"))
			tree_item.set_icon_modulate(0, _theme_source.get_theme_color("folder_icon_color", "FileDialog"))
			var placeholder := _tree.create_item(tree_item)
			placeholder.set_text(0, tr("loading..."))
			# TODO animate
			placeholder.set_icon(0, _theme_source.get_theme_icon("Progress1", "EditorIcons"))
			tree_item.set_meta("loading_placeholder", placeholder)


class Item:
	func is_loaded() -> bool:
		return false
	
	func async_expand(tree: RemoteTree) -> void:
		return
	
	func handle_item_activated() -> void:
		pass
	
	func handle_button_clicked(col: int, id: int, mouse: int) -> void:
		pass
	
	func update_visibility(filters: Array) -> void:
		pass
	
	func get_children() -> Array[Item]:
		return []
