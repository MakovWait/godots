extends GdUnitTestSuite


func test_extract_to_same_folder_uses_versions_path_directly() -> void:
	assert_str(
		RemoteEditorsControl._resolve_unzip_dir("user://__test_versions__", "Godot_v4.5-stable", true)
	).is_equal("user://__test_versions__/")


func test_extract_creates_subfolder_named_after_the_release() -> void:
	assert_str(
		RemoteEditorsControl._resolve_unzip_dir("user://__test_versions__", "Godot_v4.5-stable", false)
	).is_equal("user://__test_versions__/Godot_v4.5-stable/")
