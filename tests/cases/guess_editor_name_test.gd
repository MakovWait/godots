extends GdUnitTestSuite


func test_guess_name_matrix() -> void:
	var cases := [
		# Stable
		["Godot_v4.1-stable_linux.x86_64",        "Godot v4.1 stable"],
		["Godot_v4.1.1-stable_linux.x86_64",      "Godot v4.1.1 stable"],
		["Godot_v4.1.1.1-stable_linux.x86_64",    "Godot v4.1.1.1 stable"],
		["Godot_v4.1.1.1.1-stable_linux.x86_64",  "Godot v4.1.1.1.1 stable"],
		["godot-3.5.3-stable-win64.exe",          "Godot v3.5.3 stable"],
		["Godot_v4.3-stable_macos.universal.dmg", "Godot v4.3 stable"],

		# Prereleases
		["Godot_v4.2-rc3_mono_win64.exe",         "Godot v4.2 rc3 mono"],
		["godot-4.0-beta2-linux.x86_64",          "Godot v4.0 beta2"],
		["godot_4.0-alpha1_osx.zip",              "Godot v4.0 alpha1"],

		# Mono (no channel)
		["Godot_v4.2_mono_win64.exe",             "Godot v4.2 mono"],

		# No 'v' after godot, underscore separator
		["Godot_4.3-linux.x86_64",                "Godot v4.3"],

		# Custom/non-standard names: fallback version extraction still works
		["custom-godot-build-4.3.0.official",     "Godot v4.3.0"],

		# Fallback: no version -> returns base (last extension stripped)
		["editor",                                "editor"],
	]
	
	_assert_bulk(cases)


func test_guess_name_godot_4_5_release_assets() -> void:
	var cases := [
		# Hyphen style: channel detected
		["godot-4.5-stable.tar.xz",                            "Godot v4.5 stable"],
		["godot-4.5-stable.tar.xz.sha256",                    "Godot v4.5 stable"], # last ext stripped first

		# Dot style: channel not detected by current regex (works as designed)
		["godot-lib.4.5.stable.mono.template_release.aar",    "Godot v4.5 mono"],
		["godot-lib.4.5.stable.template_release.aar",         "Godot v4.5"],
		["Godot_native_debug_symbols.4.5.stable.editor.android.zip",           "Godot v4.5"],
		["Godot_native_debug_symbols.4.5.stable.template_release.android.zip", "Godot v4.5"],

		# Android editor builds
		["Godot_v4.5-stable_android_editor.aab",              "Godot v4.5 stable"],
		["Godot_v4.5-stable_android_editor.apk",              "Godot v4.5 stable"],
		["Godot_v4.5-stable_android_editor_horizonos.apk",    "Godot v4.5 stable"],
		["Godot_v4.5-stable_android_editor_picoos.apk",       "Godot v4.5 stable"],

		# Export templates
		["Godot_v4.5-stable_export_templates.tpz",            "Godot v4.5 stable"],
		["Godot_v4.5-stable_mono_export_templates.tpz",       "Godot v4.5 stable mono"],

		# Desktop editors
		["Godot_v4.5-stable_linux.arm32.zip",                 "Godot v4.5 stable"],
		["Godot_v4.5-stable_linux.arm64.zip",                 "Godot v4.5 stable"],
		["Godot_v4.5-stable_linux.x86_32.zip",                "Godot v4.5 stable"],
		["Godot_v4.5-stable_linux.x86_64.zip",                "Godot v4.5 stable"],
		["Godot_v4.5-stable_macos.universal.zip",             "Godot v4.5 stable"],
		["Godot_v4.5-stable_win32.exe.zip",                   "Godot v4.5 stable"],
		["Godot_v4.5-stable_win64.exe.zip",                   "Godot v4.5 stable"],
		["Godot_v4.5-stable_windows_arm64.exe.zip",           "Godot v4.5 stable"],

		# Mono desktop editors
		["Godot_v4.5-stable_mono_linux_arm32.zip",            "Godot v4.5 stable mono"],
		["Godot_v4.5-stable_mono_linux_arm64.zip",            "Godot v4.5 stable mono"],
		["Godot_v4.5-stable_mono_linux_x86_32.zip",           "Godot v4.5 stable mono"],
		["Godot_v4.5-stable_mono_linux_x86_64.zip",           "Godot v4.5 stable mono"],
		["Godot_v4.5-stable_mono_macos.universal.zip",        "Godot v4.5 stable mono"],
		["Godot_v4.5-stable_mono_win32.zip",                  "Godot v4.5 stable mono"],
		["Godot_v4.5-stable_mono_win64.zip",                  "Godot v4.5 stable mono"],
		["Godot_v4.5-stable_mono_windows_arm64.zip",          "Godot v4.5 stable mono"],

		# Web editor
		["Godot_v4.5-stable_web_editor.zip",                  "Godot v4.5 stable"],
	]
	
	_assert_bulk(cases)


func test_case_insensitivity_and_extensions() -> void:
	_assert_name("GODOT-V4.2-RC1-WIN64.EXE", "Godot v4.2 rc1")
	_assert_name("godot_v4.2-rc1.tar.xz",    "Godot v4.2 rc1") # only last extension stripped


func test_handles_long_versions() -> void:
	_assert_name("Godot_v10.20.30.40.50-stable_linux.x86_64", "Godot v10.20.30.40.50 stable")
	_assert_name("godot-v1.0.0.0.0-rc10-win64.exe",            "Godot v1.0.0.0.0 rc10")


func _assert_name(file_name: String, expected: String) -> void:
	assert_str(utils.guess_editor_name(file_name)).is_equal(expected)


func _assert_bulk(cases: Array) -> void:
	for c: Array in cases:
		_assert_name(c[0] as String, c[1] as String)
