class_name AssetCategoryOptionButton
extends OptionButton

signal changed

var _src: Src


func init(src: Src) -> void:
	_src = src


func _init() -> void:
	item_selected.connect(func(_idx: Variant) -> void: changed.emit())
	add_item(tr("All"), 0)


func async_load_items(url: String) -> Array[String]:
	clear()
	@warning_ignore("redundant_await")
	await add_item(tr("All"), 0)
	var errors: Array[String] = []
	@warning_ignore("redundant_await")
	var json := await _src.async_load(url, errors)
	for category: Dictionary in json.get("categories", []):
		add_item(tr(category.name as String), category.id as int)
	return errors


func get_selected_category_id() -> int:
	return get_selected_id()


func fill_params(params: AssetLib.Params) -> void:
	params.category = get_selected_category_id()


func _on_fetch_disable() -> void:
	disabled = true


func _on_fetch_enable() -> void:
	disabled = false


func force_select_by_label(opt_label: String) -> void:
	for i in item_count:
		if get_item_text(i) == tr(opt_label):
			select(i)
			changed.emit()


class Src:
	func async_load(url: String, errors: Array[String] = []) -> Dictionary:
		return {}


class SrcRemote:
	extends Src

	func async_load(url: String, errors: Array[String] = []) -> Dictionary:
		var response := HttpClient.Response.new(
			await HttpClient.async_http_get(url.path_join("configure?type=project"))
		)
		var info := response.to_response_info(url)
		if info.error_text:
			errors.append(info.error_text)
		var json: Variant = response.to_json()
		return json if json else {}
