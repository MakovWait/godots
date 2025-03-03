class_name AssetLibDetailsDescriptionLabel
extends RichTextLabel



func _ready() -> void:
	meta_clicked.connect(func(meta: Variant) -> void:
		OS.shell_open(str(meta))
	)


func configure(item: AssetLib.Item) -> void:
	clear()
	add_text(tr("Version:") + " " + item.version_string + "\n")
	add_text(tr("Contents:") + " ")
	push_meta(item.browse_url)
	add_text(tr("View Files"))
	pop()
	add_text("\n" + tr("Description:") + "\n\n")
	append_text(item.description)
	set_selection_enabled(true)
	set_context_menu_enabled(true)
