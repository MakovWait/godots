class_name AutoUpdates
extends Node


@export var _notification_button: NotificationsButton

var _godots_releases: GodotsRecentReleases.I
var _check_lock := false


func init(
	godots_releases: GodotsRecentReleases.I,
	updates_click_callback: Callable
) -> void:
	self._godots_releases = godots_releases
	_check_updates()
	_notification_button.pressed.connect(func() -> void:
		updates_click_callback.call()
	)


func _notification(what: int) -> void:
	if NOTIFICATION_APPLICATION_FOCUS_IN == what:
		_check_updates()


func _check_updates() -> void:
	if _check_lock: 
		return
	_check_lock = true
	await _async_check_updates()
	_check_lock = false


func _async_check_updates() -> void:
	var has_updates := await _godots_releases.async_has_updates()
	if has_updates:
		_notification_button.has_notifications = true
	else:
		_notification_button.has_notifications = false
