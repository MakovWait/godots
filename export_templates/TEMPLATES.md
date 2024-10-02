# Building Custom Export Templates

## Summary

This document outlines how to build minimized export templates for Godots. It assumes you have read and understand the basics of [building from source](https://docs.godotengine.org/en/stable/contributing/development/compiling/index.html) and [optimizing a build for size](https://docs.godotengine.org/en/stable/contributing/development/compiling/optimizing_for_size.html). Each template must be built from the associated platform.

## Building

First, the Godot git repository must be synced the the tag matching the version used by Godots.

For example:

```sh
git checkout tags/4.2.2-stable
```

Then you can use `scons` to build templates using Godots' `{platform}-custom.py` files.

```sh
scons profile=path/to/{platform}-custom.py platform={platform} target=template_release
```

The generated templates will be in the `bin` directory and can be copied over to the `release_templates` directory in the Godots project. The process can be repeated for `template_debug`.

**NOTE:** MacOS has [additonal steps to follow](https://docs.godotengine.org/en/stable/contributing/development/compiling/compiling_for_macos.html#building-export-templates) to attain the proper files and architecture support.

## Usage

The `export_presets.cfg` file is pre-configured to use these templates. You can verify they have not changed by viewing the custom template fields in the export window. **If the project's engine version ever changes, the templates need to be rebuilt.**
