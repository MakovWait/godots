extends VBoxContainer


@onready var _item_actions: VBoxContainer = $ItemActions
@onready var _tip_label: Label = $Spacer/TipLabel


func _ready() -> void:
	_handle_actions_changed()


func refresh_actions(actions):
	_clear_actions()
	_add_actions(actions)
	_handle_actions_changed.call_deferred()


func _add_actions(actions):
	for action in actions:
		_item_actions.add_child(action)


func _clear_actions():
	for action in _item_actions.get_children():
		action.queue_free()


func _handle_actions_changed():
	_tip_label.visible = _item_actions.get_child_count() == 0


func _enter_tree() -> void:
	custom_minimum_size = Vector2(120, 120) * Config.EDSCALE
