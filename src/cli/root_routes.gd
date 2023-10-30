class_name RootRoutes
extends Routes.List

func _init(ctx: CliContext) -> void:
	self._items = [
		DefaultRoutes.new(ctx),
		EditorsRoutes.new(ctx),
		ExecCommand.Route.new(ctx)
	]
