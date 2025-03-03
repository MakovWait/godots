class_name NotificationsButton
extends Button


var has_notifications := false:
	set(value):
		has_notifications = value
		if value:
			disabled = false
			modulate = Color.WHITE
		else:
			disabled = true
			modulate = Color(0.5, 0.5, 0.5, 0.5)
		queue_redraw()


func _ready() -> void:
	flat = true
	has_notifications = false


func _notification(what: int) -> void:
	if NOTIFICATION_THEME_CHANGED == what:
		icon = get_theme_icon("Notification", "EditorIcons")


func _draw() -> void:
	if not has_notifications:
		return
	var color := get_theme_color("warning_color", "Editor")
	var button_radius := size.x / 8
	draw_circle(Vector2(button_radius * 2, button_radius * 2), button_radius, color)
