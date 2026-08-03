extends GdUnitTestSuite


func test_delete_parent_folder_returns_the_editor_subfolder() -> void:
	assert_str(
		LocalEditorsControl._resolve_removal_target("/versions/Godot_v4.5-stable/godot", "/versions", true, false)
	).is_equal("/versions/Godot_v4.5-stable")


func test_delete_parent_folder_is_skipped_for_same_folder_installs() -> void:
	# The binary lives directly in the versions dir, so the guard refuses to remove it.
	assert_str(
		LocalEditorsControl._resolve_removal_target("/versions/godot", "/versions", true, false)
	).is_equal("")


func test_delete_parent_folder_is_skipped_outside_the_versions_dir() -> void:
	assert_str(
		LocalEditorsControl._resolve_removal_target("/elsewhere/godot", "/versions", true, false)
	).is_equal("")


func test_delete_binary_returns_the_binary_path() -> void:
	assert_str(
		LocalEditorsControl._resolve_removal_target("/versions/godot", "/versions", false, true)
	).is_equal("/versions/godot")


func test_no_option_selected_removes_nothing() -> void:
	assert_str(
		LocalEditorsControl._resolve_removal_target("/versions/Godot_v4.5-stable/godot", "/versions", false, false)
	).is_equal("")
