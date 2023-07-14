class_name ConfirmationDialogAutoFree
extends ConfirmationDialog


func _ready() -> void:
	visibility_changed.connect(func(): 
		if not visible:
			queue_free()
	)
	confirmed.connect(func():
		queue_free()
	)
