class_name AssetLib

# https://github.com/godotengine/godot-asset-library/blob/master/API.md
class Params:
	# any|addon|project
	var type: String = "project":
		set(value): 
			assert(value in ["any", "addon", "project"])
			type = value
	
	# category id
	var category: int = 0
	
	# official|community|testing
	var support: PackedStringArray = ["official", "community"]:
		set(value):
			for el in value:
				assert(el in ["official", "community", "testing"])
			support = value
	
	# search text
	var filter: String = ""
	
	# submitter username
	var user: String = ""
	
	# license
	var cost := ""

	# (major).(minor).(patch)
	var godot_version: String = ""
	
	# number 1…500
	var max_results: int = 40
	
	#(number, pages to skip)
	var page: int = 0
	
	# rating|cost|name|updated
	var sort: String = "updated":
		set(value): 
			assert(value in ["rating", "cost", "name", "updated"])
			sort = value
	
	var reverse := false


static func params_to_search(params: Params) -> String:
	var scalar := func(n: String, p:Variant = null) -> _UrlSearchParamBase: return _UrlSearchParamScalar.new(n, p)
	var array := func(n: String, p:Variant = null) -> _UrlSearchParamBase: return _UrlSearchParamArray.new(n, p)
	
	var parts := [
		scalar.call("type"),
		_UrlSearchParamCategory.new(),
		array.call("support"),
		scalar.call("filter"),
		scalar.call("user"),
		scalar.call("cost"),
		scalar.call("godot_version"),
		scalar.call("max_results"),
		scalar.call("page"),
		scalar.call("sort"),
		_UrlSearchParamReverse.new()
	]
	
	var result := "?"
	for part: _IUrlSearchParam in parts:
		result = part.join(result, params)
	return result


class _IUrlSearchParam:
	func join(prev: String, params: Params) -> String:
		return utils.not_implemeted()


class _UrlSearchParamBase extends _IUrlSearchParam:
	var _name: String
	var _prop: String
	
	## prop: Optional[String]
	func _init(name: String, prop: Variant = null) -> void:
		if prop == null:
			_prop = name
		else:
			_prop = prop
		_name = name


class _UrlSearchParamScalar extends _UrlSearchParamBase:
	func join(prev: String, params: Params) -> String:
		var value: Variant = params.get(_prop)
		if value is String and value == "":
			return prev
		return prev + "&{name}={value}".format({"name": _name, "value": value})


class _UrlSearchParamArray extends _UrlSearchParamBase:
	func join(prev: String, params: Params) -> String:
		var param_value: Array = params.get(_prop)
		if len(param_value) == 0:
			return prev
		var value := "+".join(param_value)
		return prev + "&{name}={value}".format({"name": _name, "value": value})


class _UrlSearchParamReverse extends _IUrlSearchParam:
	func join(prev: String, params: Params) -> String:
		if params.reverse:
			return prev + "&reverse"
		else:
			return prev


class _UrlSearchParamCategory extends _UrlSearchParamScalar:
	func _init() -> void:
		super._init("category")
	
	func join(prev: String, params: Params) -> String:
		var value := params.get(_prop) as int
		if value == 0:
			return prev
		return super.join(prev, params)


class I:
	func async_fetch(params: Params, errors: Array[String]=[]) -> Items:
		return Items.new({})

	func async_fetch_one(id: String) -> Item:
		return null


class Items:
	var result: Array[Item]:
		get:
			if _data.has('result'):
				return _data.get('result')
			else:
				var default: Array[Item] = [] 
				return default
	
	var page: int:
		get: return _data.get('page', 0)

	var pages: int:
		get: return _data.get('pages', 0)

	var page_length: int:
		get: return _data.get('page_length', 0)

	var total_items: int:
		get: return _data.get('total_items', 0)

	var _data: Dictionary
	
	func _init(data: Dictionary) -> void:
		_data = data
	

class Factory:
	func construct(url: String) -> I:
		return I.new() 


class FactoryDefault extends Factory:
	var _req: HTTPRequest
	
	func _init(req: HTTPRequest) -> void:
		_req = req
	
	func construct(url: String) -> I:
		return Fake.new(url, _req)


class Fake extends I:
	var _url: String
	var _req: HTTPRequest
	
	func _init(url: String, req: HTTPRequest) -> void:
		_url = url
		_req = req
	
	func async_fetch(params: Params, errors: Array[String]=[]) -> Items:
		_req.cancel_request()
		var response := HttpClient.Response.new(await HttpClient.async_http_get_using(
			_req,
			_url.path_join("asset") + AssetLib.params_to_search(params),
			["Accept: application/vnd.github.v3+json"]
		))
		var info := response.to_response_info(_url)
		if info.error_text:
			errors.append(info.error_text)
		var json: Variant = response.to_json()
		if json == null:
			return Items.new({})
		var result: Array[Item] = []
		for el: Dictionary in (json as Dictionary).get('result', []):
			result.append(Item.new(el))
		json.result = result
		return Items.new(json as Dictionary)

	func async_fetch_one(id: String) -> Item:
		var json: Variant = utils.response_to_json(await HttpClient.async_http_get(
			_url.path_join("asset").path_join(id),
			["Accept: application/vnd.github.v3+json"]
		))
		if json == null:
			return null
		else:
			return Item.new(json as Dictionary)


class Item:
	var _data: Dictionary
	
	## Optional String?
	var id: Variant:
		get: return _data.get("asset_id", null)

	var author: String:
		get: return _data.get("author", "")
	
	var cost: String:
		get: return _data.get("cost", "")

	var title: String:
		get: return _data.get("title", "")
	
	var category: String:
		get: return _data.get("category", "")
	
	var description: String:
		get: return _data.get("description", "")
	
	var version_string: String:
		get: return _data.get("version_string", "")
	
	var browse_url: String:
		get: return _data.get("browse_url", "")

	var download_url: String:
		get: return _data.get("download_url", "")
	
	var download_hash: String:
		get: return _data.get("download_hash", "")
	
	var icon_url: String:
		get: return _data.get("icon_url", "")
	
	var previews: Array[ItemPreview]:
		get:
			var result: Array[ItemPreview] = []
			for x: Dictionary in _data.get("previews", []):
				result.append(ItemPreview.new(x))
			return result

	func _init(data: Dictionary) -> void:
		_data = data


class ItemPreview:
	var _data: Dictionary
	
	var link: String:
		get: return _data.get("link", "")

	var thumbnail: String:
		get: return _data.get("thumbnail", "")

	var is_video: bool:
		get: return _data.get("type", "") == "video"

	func _init(data: Dictionary) -> void:
		_data = data
