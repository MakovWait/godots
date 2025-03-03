class_name AssetLibProjects
extends PanelContainer

signal download_requested(item: AssetLib.Item, icon: Texture2D)

@export var _params_sources: Array[Node] = []
@export var _item_details_scene: PackedScene


@onready var _assets_container := %AssetsContainer as AssetsContainer
@onready var _filter_edit := %FilterEdit as LineEdit
@onready var _version_option_button := %VersionOptionButton as GodotVersionOptionButton
@onready var _sort_option_button := %SortOptionButton as OptionButton
@onready var _category_option_button := %CategoryOptionButton as AssetCategoryOptionButton
@onready var _site_option_button := %SiteOptionButton as AssetLibProjectsSiteOptionButton
@onready var _support_menu_button := %SupportMenuButton as AssetLibProjectsSupportMenuButton
@onready var _scroll_container := %ScrollContainer as AssetLibScrollContainer
@onready var _status_label := %StatusLabel as Label
@onready var _error_container := %ErrorContainer as AssetLibProjectsErrorContainer
@onready var _retry_button_container := %RetryButtonContainer as AssetLibProjectsRetryButtonContainer

var _params_sources_composed: ParamSources
var _asset_lib_factory: AssetLib.Factory

var _current_page := 0
var _top_pages: HBoxContainer
var _bottom_pages: HBoxContainer
var _versions_loaded := false
var _config_loaded := false
var _initial_fetch := false
var _fetching := false
var _next_fetch_queued := false


func init(
	asset_lib_factory: AssetLib.Factory, 
	category_src: AssetCategoryOptionButton.Src,
	version_src: GodotVersionOptionButton.Src,
	images_src: RemoteImageSrc.I
) -> void:
	_category_option_button.init(category_src)
	_version_option_button.init(version_src)
	_asset_lib_factory = asset_lib_factory
	
	_assets_container.init(images_src)
	_assets_container.title_pressed.connect(func(item: AssetLib.Item) -> void:
		var asset_lib := _get_asset_lib()
		var item_details: AssetLibItemDetailsDialog = _item_details_scene.instantiate()
		item_details.download_requested.connect(func(item: AssetLib.Item, icon: Texture2D) -> void:
			download_requested.emit(item, icon)
		)
		item_details.init(item.id as String, asset_lib, images_src)
		add_child(item_details)
		item_details.popup_centered()
	)
	_assets_container.category_pressed.connect(func(item: AssetLib.Item) -> void:
		_category_option_button.force_select_by_label(item.category)
	)

	if is_visible_in_tree():
		_async_fetch()
		_initial_fetch = true


func _init() -> void:
	visibility_changed.connect(func() -> void:
		if is_visible_in_tree() and not _initial_fetch:
			_async_fetch()
			_initial_fetch = true
	)


func _ready() -> void:
	_params_sources_composed = ParamSources.new(_params_sources)
	
	(%LibVb as Control).add_theme_constant_override("separation", 20 * Config.EDSCALE)
	_filter_edit.placeholder_text = tr("Search Templates, Projects, and Demos")
	
	_assets_container.add_theme_constant_override("h_separation", 10 * Config.EDSCALE)
	_assets_container.add_theme_constant_override("v_separation", 10 * Config.EDSCALE)
	
	_params_sources_composed.connect_changed(func() -> void:
		_current_page = 0
		_async_fetch()
	)
	
	_site_option_button.site_selected.connect(func() -> void:
		_config_loaded = false
		_async_fetch()
	)
	
	(%TopPagesContainer as PaginationContainer).page_changed.connect(_change_page)
	(%BotPagesContainer as PaginationContainer).page_changed.connect(_change_page)


func _async_fetch() -> void:
	if _fetching:
		_next_fetch_queued = true
		return

	_fetching = true
	_next_fetch_queued = false

	if not _versions_loaded:
		var version_error := await __async_load_versions_list()
		if version_error:
			return
	
	if not _config_loaded:
		var config_error := await __async_load_configuration()
		if config_error:
			return
	
	await __async_fetch_assets()
	
	_fetching = false
	if _next_fetch_queued:
		_async_fetch()


func __async_load_versions_list() -> Error:
	_versions_loaded = false
	_scroll_container.dim()
	_params_sources_composed.disable()
	_set_status(tr("Loading version list..."))
	_assets_container.clear()
	_clear_pages()

	var versions_load_errors := await _version_option_button.async_load_versions()
	var return_error: Error
	if len(versions_load_errors) > 0:
#		_show_config_error(config_load_errors)
		_status_label.show()
		_status_label.text = tr("Failed to get versions list.")
		_error_container.set_text(versions_load_errors[0])
		_retry_button_container.create(func() -> void: _async_fetch())
		return_error = FAILED
	else:
		_params_sources_composed.enable()
		_versions_loaded = true
		return_error = OK
	_scroll_container.bright()
	return return_error


func __async_load_configuration() -> Error:
	_config_loaded = false
	_retry_button_container.clear()
	_params_sources_composed.disable()
	_set_status(tr("Loading configuration..."))
	_assets_container.clear()
	_clear_pages()
	_scroll_container.dim()
	_error_container.hide()

	var config_load_errors := await _category_option_button.async_load_items(
		_site_option_button.get_selected_site()
	)

	var return_err: Error = OK
	if len(config_load_errors) > 0:
		_set_status(tr("Failed to get repository configuration."))
		_error_container.set_text(config_load_errors[0])
		_retry_button_container.create(func() -> void: _async_fetch())
		_site_option_button.enable()
		return_err = FAILED
	else:
		_config_loaded = true
		_params_sources_composed.enable()
		return_err = OK
	_scroll_container.bright()
	return return_err


func __async_fetch_assets() -> void:
	_retry_button_container.clear()
	_error_container.hide()
	_scroll_container.dim()
	#_params_sources_composed.disable()

	var asset_lib := _get_asset_lib()
	var params := _get_asset_lib_params()
	var errors: Array[String] = []
	var items := await asset_lib.async_fetch(params, errors)

	if len(errors) > 0:
		_error_container.set_text(errors[0])
		_retry_button_container.create(func() -> void: _async_fetch())
	_setup_pages(items)
	_assets_container.fill(items.result)
	#_params_sources_composed.enable()
	_scroll_container.bright()
	_update_fetch_assets_status_label(items, params, errors)


func _get_asset_lib() -> AssetLib.I:
	return _asset_lib_factory.construct(_site_option_button.get_selected_site())


func _get_asset_lib_params() -> AssetLib.Params:
	var params := AssetLib.Params.new()
	_params_sources_composed.fill_params(params)
	params.page = _current_page
	return params


func _update_fetch_assets_status_label(items: AssetLib.Items, params: AssetLib.Params, errors: Array[String]) -> void:
	if len(errors) > 0:
		_set_status(tr("Failed to load assets list."))
		return
	if len(items.result) == 0:
		if params.filter.is_empty():
			_set_status(tr(
				"No results compatible with Godot %s for support level(s): %s.\nCheck the enabled support levels using the 'Support' button in the top-right corner."
			) % [params.godot_version, _support_menu_button.get_support_string()])
		else:
			_set_status(tr(
				"No results for \"%s\" for support level(s): %s." % [
					params.filter, _support_menu_button.get_support_string()
				]
			))
	else:
		_status_label.hide()


func _change_page(p: int) -> void:
	_current_page = p
	_async_fetch()


func _clear_pages() -> void:
	(%TopPagesContainer as PaginationContainer).clear()
	(%BotPagesContainer as PaginationContainer).clear()


func _setup_pages(items: AssetLib.Items) -> void:
	_clear_pages()
	(%TopPagesContainer as PaginationContainer).render(items.page, items.pages, items.page_length, items.total_items)
	(%BotPagesContainer as PaginationContainer).render(items.page, items.pages, items.page_length, items.total_items)


func _notification(what: int) -> void:
	if NOTIFICATION_THEME_CHANGED == what:
		# quering since this is called before node is ready
		(%ScrollContainer as Control).add_theme_stylebox_override("panel", get_theme_stylebox("panel", "Tree"))
		(%FilterEdit as LineEdit).right_icon = get_theme_icon("Search", "EditorIcons")


func _set_status(text: String) -> void:
	_status_label.show()
	_status_label.text = text


class ParamSources:
	var _elements: Array
	
	func _init(elements: Array) -> void:
		_elements = elements
	
	func enable() -> void:
		for x: Object in _elements:
			if x.has_method("_on_fetch_enable"):
				x.call("_on_fetch_enable")
	
	func disable() -> void:
		for x: Object in _elements:
			if x.has_method("_on_fetch_disable"):
				x.call("_on_fetch_disable")

	func connect_changed(callback: Callable) -> void:
		for x: Object in _elements:
			if x.has_signal("changed"):
				x.connect("changed", callback)
	
	func fill_params(params: AssetLib.Params) -> void:
		for x: Object in _elements:
			if x.has_method("fill_params"):
				x.call("fill_params", params)
