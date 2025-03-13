class_name ShowOwnersDialog
extends AcceptDialog


@onready var _tree: Tree = $Tree


enum Buttons {
	OPEN_IN_EXPLORER,
	RUN,
	EDIT
}


func raise(editor: LocalEditors.Item) -> void:
	var projects: Projects.List = Context.use(self, Projects.List)
	var owners := projects.get_owners_of(editor)
	for owner in owners:
		var item := _tree.create_item()
		var icon_image: Image = owner.icon.get_image().duplicate()
		icon_image.resize(
			16 * Config.EDSCALE,
			16 * Config.EDSCALE,
			Image.INTERPOLATE_LANCZOS
		)
		item.set_icon(0, ImageTexture.create_from_image(icon_image))
		item.set_text(0, owner.name)
		item.add_button(
			0, 
			get_theme_icon("Play", "EditorIcons"), 
			Buttons.RUN, 
			not owner.is_valid, 
			tr("Run")
		)
		item.add_button(
			0, 
			get_theme_icon("Edit", "EditorIcons"), 
			Buttons.EDIT, 
			not owner.is_valid, 
			tr("Edit")
		)
		item.add_button(
			0, 
			get_theme_icon("Folder", "EditorIcons"), 
			Buttons.OPEN_IN_EXPLORER, 
			not owner.is_valid, 
			tr("Show in File Manager")
		)
		item.set_metadata(0, owner)
	title = tr("References of %s (%s)") % [editor.name, len(owners)]
	popup_centered()


func _ready() -> void:
	min_size = Vector2(350, 350) * Config.EDSCALE
	visibility_changed.connect(func() -> void:
		if not visible:
			queue_free()
	)
	
	_tree.button_clicked.connect(func(item: TreeItem, column: int, id: int, mouse_button_index: int) -> void:
		var project: Projects.Item = item.get_metadata(0)
		if id == Buttons.EDIT:
			project.edit()
		if id == Buttons.RUN:
			project.run()
		if id == Buttons.OPEN_IN_EXPLORER:
			OS.shell_show_in_file_manager(
				ProjectSettings.globalize_path(project.path)
			)
	)
	
	_tree.create_item()
	_tree.hide_root = true
