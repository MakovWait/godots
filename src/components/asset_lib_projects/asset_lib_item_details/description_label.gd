extends RichTextLabel



func _ready():
	meta_clicked.connect(func(meta):
		OS.shell_open(meta)
	)


func configure(item: AssetLib.Item):
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
