class_name AssetLibProjectsSupportMenuButton
extends MenuButton

signal changed

enum Options {
	SUPPORT_OFFICIAL,
	SUPPORT_COMMUNITY,
	SUPPORT_TESTING
}

const options_text := {
	Options.SUPPORT_OFFICIAL: "Official",
	Options.SUPPORT_COMMUNITY: "Community",
	Options.SUPPORT_TESTING: "Testing"
}

const options_id = {
	Options.SUPPORT_OFFICIAL: "official",
	Options.SUPPORT_COMMUNITY: "community",
	Options.SUPPORT_TESTING: "testing"
}

func _init() -> void:
	var popup := get_popup()
	popup.hide_on_checkable_item_selection = false
	
	add_check_item(Options.SUPPORT_OFFICIAL)
	add_check_item(Options.SUPPORT_COMMUNITY)
	add_check_item(Options.SUPPORT_TESTING)
	
	set_item_checked(Options.SUPPORT_OFFICIAL)
	set_item_checked(Options.SUPPORT_COMMUNITY)
	
	popup.id_pressed.connect(func(id: int) -> void:
		var idx := popup.get_item_index(id)
		popup.set_item_checked(idx, not popup.is_item_checked(idx))
		changed.emit()
	)


func fill_params(params: AssetLib.Params) -> void:
	var result := []
	for i in get_popup().item_count:
		if get_popup().is_item_checked(i):
			result.append(options_id[get_popup().get_item_id(i)])
	params.support = result


func add_check_item(opt: int) -> void:
	get_popup().add_check_item(tr(options_text[opt] as String), opt)


func set_item_checked(opt: int) -> void:
	get_popup().set_item_checked(opt, true)


func get_support_string() -> String:
	var result := []
	for i in get_popup().item_count:
		if get_popup().is_item_checked(i):
			result.append(tr(options_text[get_popup().get_item_id(i)] as String))
	return "+".join(result)


func _on_fetch_disable() -> void:
	disabled = true


func _on_fetch_enable() -> void:
	disabled = false
