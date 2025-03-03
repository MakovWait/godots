extends OptionButton


signal changed 


var data := {
	0: {
		"text": tr("Recently Updated"),
		"reverse": false,
		"sort": "updated"
	},
	1: {
		"text": tr("Least Recently Updated"),
		"reverse": true,
		"sort": "updated"
	},
	2: {
		"text": tr("Name (A-Z)"),
		"reverse": false,
		"sort": "name"
	},
	3: {
		"text": tr("Name (Z-A)"),
		"reverse": true,
		"sort": "name"
	},
	4: {
		"text": tr("License (A-Z)"),
		"reverse": false,
		"sort": "cost"
	},
	5: {
		"text": tr("License (Z-A)"),
		"reverse": true,
		"sort": "cost"
	},
}


func _init() -> void:
	item_selected.connect(func(_idx: int) -> void: changed.emit())
	for key: int in data.keys():
		add_item(data[key].text as String, int(key))


func fill_params(params: AssetLib.Params) -> void:
	var selected_id := get_selected_id()
	var el: Dictionary = data.get(selected_id, data[0])
	params.sort = el.sort
	params.reverse = el.reverse


func _on_fetch_disable() -> void:
	disabled = true


func _on_fetch_enable() -> void:
	disabled = false
