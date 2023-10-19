class_name LocalEditorTests
extends GdUnitTestSuite

const config_path = "res://tests/cases/services/assets/editors.cfg"

func test_filter_by_name_return(name: String, expected: int, test_parameters:= [
	["4.1", 3],
	["4.1s", 1],
	["4.1   s", 1],
	["   4.1   s", 1],
	["4.1 StAble", 1],
	["invalid", 0],
]):
	var editors = LocalEditors.List.new(config_path)
	editors.load()
	var result = editors.filter_by_name_pattern(name)
	assert(result.size() == expected)
