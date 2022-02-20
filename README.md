# Kanban Tasks - Todo Manager
Kanban Tasks - Todo Manager is a kanban board addon for the [godot engine](https://godotengine.org).

## Motivation
When managing single projects using an external app like trello is to much. Also I like to keep the todos attatched to the project.  
I found other kanban addons to not integrate well into the default editor look and feel of godot. So it was my focus to addapt the look and feel of godot. (Or what I believe the look and feel to be.)

### Why this long name?
I wanted the plugin to be findable with the keywords `kanban`, `todo` and `tasks`. So this is what I came up with.

## Features
- Renamable stages
- Tasks with detailed description and titles
- Search in tasks and task details
- Intuitive drag and drop usage utilising the godot build in drag and drop
- Support for shortcuts \*
- Categories \*\*
- Diffrent stage layouts with multiple stages per column \*\*\*
- Supports all editor themes including light ones

\* uses godot defaults because the custom shortcuts cannot be accessed; not tested on mac (would be nice if someone could test)  
\*\* new categories can currently only be added via edditing the `data.json` file  
\*\*\* the layout can currently only be changed via edditing the `data.json` file  

## Where is the data stored?
The data is stored inside of the addon folder (`res://addons/kanban_tasks/data.json`).
Currently some features require edditing the file to use. Do this before adding tasks to prevent save file corruption. You can have a look at the `examples` folder for some example data configurations.

## I found a bug. What should I do?
The plugin is work in progress. Feel free to add an bug report on the [github](https://github.com/HolonProduction/godot_kanban_tasks) page.

## Should I look at the code?
No you should not! It does not correspond to the styling guides and is very chaotic. I postponed refactoring to Godot 4.0.

## Under which license is this?
The plugin is under the MIT license.  

You should put the plugin in your build exceptions to prevent exporting it it. (Don't know if this is neccessary).

## Can I get some screenshots please?