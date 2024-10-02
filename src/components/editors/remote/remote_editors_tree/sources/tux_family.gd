class_name RemoteEditorsTreeDataSourceTuxFamily


class Self extends RemoteEditorsTreeDataSource.I:
	const url = "https://downloads.tuxfamily.org/godotengine/"
	const platforms = {
		"X11": {
			"suffixes": ["_x11.64.zip", "_linux.64.zip", "_linux.x86_64.zip", "_linux.x86_32.zip", "_linux_x86_64.zip", "_linux_x86_32.zip"],
		},
		"OSX": {
			"suffixes": ["_osx.universal.zip", "_macos.universal.zip", "_osx.fat.zip", "_osx32.zip", "_osx64.zip"],
		},
		"Windows": {
			"suffixes": ["_win64.exe.zip", "_win32.exe.zip", "_win64.zip", "_win32.zip"],
		}
	}
	
	var _assets: RemoteEditorsTreeDataSource.RemoteAssets
	
	func _init(assets):
		_assets = assets
	
	func setup(tree: Tree):
		var root = tree.create_item()
		root.set_meta("delegate", RemoteTreeItemTuxFamily.new(root, _assets, true))
		root.set_meta("url_part", url)
	
	func cleanup(tree: Tree):
		tree.clear()
	
	func get_platform_suffixes():
		var current_platform
		if OS.has_feature("windows"):
			current_platform = platforms["Windows"]
		elif OS.has_feature("macos"):
			current_platform = platforms["OSX"]
		elif OS.has_feature("linux"):
			current_platform = platforms["X11"]
		return current_platform["suffixes"]
	
	func to_remote_item(item: TreeItem) -> RemoteEditorsTreeDataSource.Item:
		return item.get_meta("delegate")


class RemoteTreeItemTuxFamily extends RemoteEditorsTreeDataSource.Item:
	var _item: TreeItem
	var _assets: RemoteEditorsTreeDataSource.RemoteAssets
	var _is_tree_root: bool
	
	func _init(item: TreeItem, assets: RemoteEditorsTreeDataSource.RemoteAssets, is_tree_root: bool):
		_item = item
		_assets = assets
		_is_tree_root = is_tree_root
	
	func is_loaded() -> bool:
		return _item.has_meta("loaded")
	
	func async_expand(tree: RemoteEditorsTreeDataSource.RemoteTree):
		_item.set_meta("loaded", true)
		
		var resp = await HttpClient.async_http_get(_restore_url(_item))
		var body = XML.parse_buffer(resp[3])
		var tbody = exml.smart(body.root).find_smart_child_recursive(
			exml.Filters.by_name("tbody")
		)
		if not tbody: return
		var nodes = []
		for node in tbody.iter_children_recursive():
			nodes.append(node)
		if _is_tree_root:
			nodes.reverse()
		for node in nodes:
			if node.name == "tr":
				var row = TuxfamilyRow.new(node, _is_tree_root)
				var tree_item = tree.create_item(_item)
				tree_item.set_text(0, row.name)
				tree_item.set_meta("delegate", RemoteTreeItemTuxFamily.new(tree_item, _assets, false))

				if row.is_dir:
					tree.set_as_folder(tree_item)
				elif row.is_zip:
					tree_item.set_icon(0, tree.theme_source.get_theme_icon("Godot", "EditorIcons"))
					# FIX save ref to button_click_handler etc.
					var btn_texture: Texture2D = tree.theme_source.get_theme_icon("AssetLib", "EditorIcons")
					tree_item.add_button(0, btn_texture)
				
				tree_item.collapsed = true
				tree_item.set_meta("url_part", row.href)
				tree_item.set_meta("file_name", row.name)
				tree_item.set_meta("row", row)
		tree.free_loading_placeholder(_item)
	
	func get_children() -> Array[RemoteEditorsTreeDataSource.Item]:
		var result: Array[RemoteEditorsTreeDataSource.Item] = []
		for child in _item.get_children():
			if child.has_meta("delegate"):
				result.append(child.get_meta("delegate"))
		return result

	func handle_item_activated():
		if not _item.has_meta("file_name"): return
		var file_name = _item.get_meta("file_name")
		var url = _restore_url(_item)
		_assets.download(url, file_name)

	func handle_button_clicked(col, id, mouse):
		if not _item.has_meta("file_name"): return
		var file_name = _item.get_meta("file_name")
		var url = _restore_url(_item)
		_assets.download(url, file_name)

	func update_visibility(filters):
		if _item.has_meta("row"):
			var row = _item.get_meta("row")
			_item.visible = _should_be_visible(row, filters)
	
	func _should_be_visible(row: TuxfamilyRow, filters):
		if row.is_parent_ref:
			return false
		
		if row.is_file and not row.is_zip:
			return false

		for filter in filters:
			if filter.test(FilterTargetTuxfamilyRow.new(row)):
				return false
		
		return true

	func _restore_url(item: TreeItem):
		var path_steps = []
		var path_src = item
		while path_src != null:
			path_steps.append(path_src.get_meta("url_part"))
			path_src = path_src.get_parent()
		path_steps.reverse()
		var result_url = "".join(path_steps)
		return result_url


class FilterTargetTuxfamilyRow extends RemoteEditorsTreeDataSource.FilterTarget:
	var _row: TuxfamilyRow
	
	func _init(row):
		_row = row
	
	func is_possible_version_folder() -> bool:
		return _row.is_possible_version_folder
	
	func is_file() -> bool:
		return _row.is_file
	
	func is_for_different_platform(platform_suffixes) -> bool:
		return _row.is_for_different_platform(platform_suffixes)
	
	func get_name() -> String:
		return _row.name


class TuxfamilyRow extends RefCounted:
	var _src: exml.XMLNodeSmart
	var _is_possible_version_folder = false
	
	var is_parent_ref:
		get: return self.href == "../"
	
	var href: 
		get: return _src.find_smart_child_recursive(exml.Filters.by_name("a")).attr("href")
	
	var is_dir:
		get: return self.type == "Directory"
	
	var type:
		get: return _src.find_child_recursive(exml.Filters.by_attr("class", "t")).content
	
	var name: String:
		get: return _src.find_child_recursive(exml.Filters.by_name("a")).content
	
	var is_zip:
		get: return self.type == "application/zip"
	
	var is_file:
		get: return not is_dir
	
	var is_possible_version_folder:
		get: return _is_possible_version_folder
	
	func _init(src, is_possible_version_folder=false):
		if src is exml.XMLNodeSmart:
			_src = src
		else:
			_src = exml.smart(src)
		_is_possible_version_folder = is_possible_version_folder
	
	func is_for_different_platform(platform_suffixes):
		var cached_name = name
		return not platform_suffixes.any(func(suffix): return cached_name.ends_with(suffix))
