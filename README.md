# :pencil2: Kanban Tasks - Todo Manager
[![itch.io](https://img.shields.io/static/v1?label=Itch&message=standalone&color=grey&logo=itch.io&logoColor=white&labelColor=fa5c5c)](https://holonproduction.itch.io/kanban-tasks)
[![Godot 4.x](https://img.shields.io/static/v1?label=Godot&message=4.x&color=grey&logo=godotengine&logoColor=white&labelColor=478cbf)](https://store.godotengine.org/asset/holonproduction/kanban-tasks/)
[![Godot 3.x](https://img.shields.io/static/v1?label=Godot&message=3.x&color=grey&logo=godotengine&logoColor=white&labelColor=478cbf)](https://godotengine.org/asset-library/asset/1245)

Kanban Tasks - Todo Manager is a minimalistic kanban board application aimed at solo developers. It is available as addon for the [Godot Engine](https://godotengine.org) or as standalone application.

## :seedling: Setup
The editor plugin can be installed from the Godot Asset Store.

## :rocket: Features
- Tasks with detailed description and title
- Intuitive drag and drop usage
- Customizable stage layout
- Shortcuts for common actions
- Categories to organize your tasks
- Integrates well with all Godot editor themes including light ones

## :question: Q & A

### :anger: Now that there is a standalone version will the editor plugin be discontinued?
No. Both versions are using the same codebase therefore new features and changes are only implemented once.
### :floppy_disk: Where is the data stored?
When using the editor plugin your board data can be found under `res://kanban_tasks_data.kanban`. You may want to backup it from time to time. Settings that are not related to a specific board are stored in the editor settings.
### :speech_balloon: Why this long name?
I wanted the plugin to be findable with the keywords `kanban`, `todo` and `tasks`. So this is what I came up with.
### :camera: Can I get some screenshots please?
|     |     |
|:---:|:---:|
| ![screenshot](./images/editor_empty.png) | ![screenshot](./images/standalone_empty.png) |
| ![screenshot](./images/standalone.png) | ![screenshot](./images/editor.png) |
| ![screenshot](./images/settings_categories.png) | ![screenshot](./images/settings_stages.png) |


## :hammer: Building a release version

To build a release version of the plugin and standalone versions use the `res://build_logic/bundle.gd` utility. It ensures that the license is correctly included in the distributed zips.
The build script is only supported on linux.
