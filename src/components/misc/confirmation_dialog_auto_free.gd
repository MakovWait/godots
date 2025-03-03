class_name ConfirmationDialogAutoFree
extends ConfirmationDialog


func _ready() -> void:
	visibility_changed.connect(func() -> void: 
		if not visible:
			queue_free()
	)
	confirmed.connect(func() -> void:
		queue_free()
	)
