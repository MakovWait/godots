extends OptionButton

signal site_selected

const default_site = "https://godotengine.org/asset-library/api"
var default_repositories = {
	"godotengine.org (Official)": default_site
}


func _init():
	item_selected.connect(func(_idx): 
		site_selected.emit()
	)
	_update_options()


func _on_fetch_disable():
	disabled = true


func _on_fetch_enable():
	disabled = false


func enable():
	disabled = false


func _update_options():
	clear()
	var repositories = Config.editor_settings_proxy_get(
		"asset_library/available_urls", 
		default_repositories
	)
	var idx = 0
	for key in repositories.keys():
		add_item(key)
		set_item_metadata(idx, repositories[key])
		idx += 1


func get_selected_site():
	if get_selected_id() == -1:
		return default_site
	return get_selected_metadata()
