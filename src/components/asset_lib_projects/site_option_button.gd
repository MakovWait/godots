class_name AssetLibProjectsSiteOptionButton
extends OptionButton

signal site_selected

const default_site = "https://godotengine.org/asset-library/api"
var default_repositories := {
	"godotengine.org (Official)": default_site
}


func _init() -> void:
	item_selected.connect(func(_idx: int) -> void: 
		site_selected.emit()
	)
	_update_options()


func _on_fetch_disable() -> void:
	disabled = true


func _on_fetch_enable() -> void:
	disabled = false


func enable() -> void:
	disabled = false


func _update_options() -> void:
	clear()
	var repositories := Config.editor_settings_proxy_get(
		"asset_library/available_urls", 
		default_repositories
	) as Dictionary
	var idx := 0
	for key: String in repositories.keys():
		add_item(key)
		set_item_metadata(idx, repositories[key])
		idx += 1


func get_selected_site() -> String:
	if get_selected_id() == -1:
		return default_site
	return get_selected_metadata()
