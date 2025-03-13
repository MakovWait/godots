class_name LocalEditorTests
extends GdUnitTestSuite

const config_path = "res://tests/cases/services/assets/editors.cfg"

func test_filter_by_name_pattern(name: String, expected: int, test_parameters:= [
	["4.1", 3],
	["4.1s", 1],
	["4.1   s", 1],
	["   4.1   s", 1],
	["4.1 StAble", 1],
	["invalid", 0],
]) -> void:
	var editors := LocalEditors.List.new(config_path)
	editors.load()
	var result := LocalEditors.Selector.new().by_name(name).select(editors)
	assert_int(result.size()).is_equal(expected)
