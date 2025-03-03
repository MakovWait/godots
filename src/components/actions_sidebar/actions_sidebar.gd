class_name ActionsSidebarControl
extends VBoxContainer


@onready var _item_actions: VBoxContainer = %ItemActions
@onready var _tip_label: Label = %TipLabel


func _ready() -> void:
	_handle_actions_changed()


func refresh_actions(actions: Array) -> void:
	_clear_actions()
	_add_actions(actions)
	_handle_actions_changed.call_deferred()


func _add_actions(actions: Array) -> void:
	for action: Control in actions:
		_item_actions.add_child(action)


func _clear_actions() -> void:
	for action: Control in _item_actions.get_children():
		action.hide()
		action.queue_free()


func _handle_actions_changed() -> void:
	_tip_label.visible = _item_actions.get_child_count() == 0


func _enter_tree() -> void:
	custom_minimum_size = Vector2(150, 120) * Config.EDSCALE
