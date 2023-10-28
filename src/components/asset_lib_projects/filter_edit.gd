extends LineEdit

signal changed

## seconds
@export var _debounce_time = 0.25


func _init():
	var debounce_timer = Timer.new()
	add_child(debounce_timer)
	debounce_timer.one_shot = true
	debounce_timer.timeout.connect(func(): changed.emit())
	text_changed.connect(func(_new_text):
		debounce_timer.start(_debounce_time)
	)


func fill_params(params: AssetLib.Params):
	params.filter = text.strip_edges()


func _on_fetch_disable():
	editable = false


func _on_fetch_enable():
	editable = true
