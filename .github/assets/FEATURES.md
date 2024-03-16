# Version hint
Version hint feature enables Godots to properly detect wich version of Godot Engine a project requires. 
The hint consists of:
1) version (4.0 or 4.0.1)
2) stage (stable, dev, beta..) - default value is `stable`
3) optional `mono` arg

```gdscript
"x.x.x-stage-mono"
"x.x.x-stage"
e.g.
  "4.1.2-stable-mono"
  "4.1" # the same as (4.1-stable)
  "4.1-mono" # the same as (4.1-stable-mono)
```

### Project Hint
To set the project hint, press `Rename` button in project actions.

>or edit `project.godot` file manually:
```.tscn
# res://project.godot file:
..
[godots]
version_hint=4.1.2
..
```

### Editor Hint
To set the editor hint, press `Rename` button in editor actions.
By default the hint is extracted from editor name:
```gdscript
"Godot v4.2 beta4 mono" => "v4.2-beta4-mono"
```

### .godot-version
`.godot-version` file is used only in cli mode if `project.godot` was not provided (useful for running scripts).
to setup the file just create one and fill it with `version_hint`
```
# .godot-version file:
4.1-stable
```


# CLI

Godots v1.2 introduces cli support. 

> It is recommended to place your `Godots` binary in your `PATH` environment variable, so it can be executed easily from any place by typing `godots`


### Pass a command to an editor
```
  godots exec -- <args>
```
e.g.
```
  godots exec --headless -- -q --headless --export-release "Windows Desktop"
```
Depending on the context, Godots tries to recognize what editor the `args` should be passed to and pass them to it. 
To find the editor, Godots analyzes `args`, if they are provided (for instance 
```
godots exec -- --path path/to/project
godots exec -- path/to/scene.tscn
godots exec -- -s path/to/script.gd
```
or it looks up to Working Dir in order to find either `project.godot` or `.godot-version` and read the `version_hint` from them.
> Note: if -u|--upwards is in `args`, Godots will analyze folders upwards in order to find `project.godot` or `.godot-version`

To specify the editor manually:
```
  # -n | --name
  godots exec -n "editor name" -- -p

  # -vh | --version-hint
  godots exec -vh "version_hint" -- -p

  # can be combined to achieve AND look up behaviour
  godots exec -n "editor name" -vh "version_hint" -- -e
```


### Open last edited project
Open last edited project.
```
  godots -r
  godots --recent
```


### Display editors list
```
  godots editor list
```


### Help
To see all the available commands type
```
  godots -gh
  godots --ghelp
```

# Custom Command
By default, there are two commands for project (Run, Edit) and one for editor (Run).

Commands are able to be activated via RMB click on item:

![image](https://github.com/MakovWait/godots/assets/39778897/3bd508b4-b21e-403e-b49c-fe745693907a)

### Edit Commands

Also there is an option 'Edit Commands' (within named section 'Commands') that enables you to create custom commands or edit default ones (Run, Edit).
For instance, command to open the project in terminal:

![image](https://github.com/MakovWait/godots/assets/39778897/e1c47d67-9351-4fdd-a507-dcddab00b77c)

The command uses `{{PROJECT_DIR}}` variable, the full list of them:

| Variable        | Description                               | Scope              |
| --------------- | ----------------------------------------- | ------------------ |
| {{PROJECT_DIR}} | the project directory                     | `project`          |
| {{EDITOR_DIR}}  | the editor directory                      | `editor` `project` |
| {{EDITOR_PATH}} | the bind editor \| editor itself bin path | `editor` `project` |
