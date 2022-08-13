# Kanban Tasks - Todo Manager
Kanban Tasks - Todo Manager is a kanban board addon for the [godot engine](https://godotengine.org).

>The version 1.0 contains a bug that breaks your project when exporting. Upgrade to 1.0.1 as soon as possible.

## Features
- Renamable stages
- Tasks with detailed description and titles
- Search in tasks and task details
- Intuitive drag and drop usage utilising the godot build in drag and drop
- Support for shortcuts \*
- Categories
- Different stage layouts with multiple stages per column
- Supports all editor themes including light ones

\* uses godot defaults because the custom shortcuts cannot be accessed; not tested on mac (would be nice if someone could test)

## Where is the data stored?
The data is stored inside of the addon folder (`res://addons/kanban_tasks/data.json`).
You can have a look at the `examples` folder for some example data configurations.

## I found a bug. What should I do?
Feel free to report bugs or feature requests on the [github](https://github.com/HolonProduction/godot_kanban_tasks) page.

## Motivation
When managing single projects using an external app like trello is to much. Also I like to keep the todos attached to the project.  
I found other kanban addons to not integrate well into the default editor look and feel of godot. So it was my focus to adapt the look and feel of godot. (Or what I believe the look and feel to be.)

### Why this long name?
I wanted the plugin to be findable with the keywords `kanban`, `todo` and `tasks`. So this is what I came up with.

## Should I look at the code?
No you should not! It does not correspond to the styling guides and is very chaotic. I postponed refactoring to Godot 4.0.

## Under which license is this?
The plugin is under the MIT license.  

You should put the plugin in your build exceptions to prevent exporting it it. (Don't know if this is necessary).

## Can I get some screenshots please?
![screenshot](https://raw.githubusercontent.com/HolonProduction/godot_kanban_tasks/master/images/screenshot1.png)
![screenshot](https://raw.githubusercontent.com/HolonProduction/godot_kanban_tasks/master/images/screenshot2.png)
![screenshot](https://raw.githubusercontent.com/HolonProduction/godot_kanban_tasks/master/images/screenshot3.png)
