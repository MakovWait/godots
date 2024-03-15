class_name CustomCommandsPopupItems


class Self:
	var _edit_commands: Action.Self
	var _commands: CommandViewer.Commands
	
	func _init(edit_commands: Action.Self, commands: CommandViewer.Commands):
		_commands = commands
		_edit_commands = edit_commands

	func fill(popup: PopupMenu):
		var commands = _commands.all()
		popup.add_separator(tr("Commands"))
		
		# edit control
		popup.add_item(_edit_commands.label)
		popup.set_item_tooltip(popup.item_count - 1, _edit_commands.tooltip)
		popup.set_item_icon(popup.item_count - 1, _edit_commands.icon.texture())
		popup.set_item_metadata(popup.item_count - 1, {'on_pressed': func():
			_edit_commands.act()
		})
		
		for command in commands:
			if ["Run", "Edit"].has(command.name()):
				continue
			popup.add_item(command.name())
			popup.set_item_metadata(popup.item_count - 1, {'on_pressed': func():
				command.create_process()
			})
			popup.set_item_icon(
				popup.item_count - 1, 
				popup.get_theme_icon(command.icon(), "EditorIcons")
			)
