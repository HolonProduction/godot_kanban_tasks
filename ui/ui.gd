extends Control


class BottomPanelItem extends RefCounted:
	var button: Button
	var control: Control
	var name: String


const Interface := preload("res://standalone_plugin/standalone/interface.gd")
const UndoRedoManager := preload("res://standalone_plugin/standalone/undo_redo_manager.gd")

enum {
	DOCK_SLOT_LEFT_UL,
	DOCK_SLOT_LEFT_BL,
	DOCK_SLOT_LEFT_UR,
	DOCK_SLOT_LEFT_BR,
	DOCK_SLOT_RIGHT_UL,
	DOCK_SLOT_RIGHT_BL,
	DOCK_SLOT_RIGHT_UR,
	DOCK_SLOT_RIGHT_BR,
	DOCK_SLOT_MAX,
}

var bottom_panel_items: Array[BottomPanelItem] = []

var distraction_free_mode: bool:
	set(v):
		distraction_free_button.set_pressed_no_signal(v)
		__update_visibility()
	get:
		return distraction_free_button.is_pressed()

var interface = Interface.new()
var undo_redo_manager = UndoRedoManager.new()

var dock_select: Control
var dock_tab_move_right: Button
var dock_tab_move_left: Button
var dock_popup_selected_idx: int
var dock_select_rect_over_idx: int = -1

var main_editors: Array = []
var current_main_editor: int = -1
var main_editor_buttons: Array[Button] = []

var stylebox_content_no_tabbar: StyleBox

var dock_select_rects: Array[Rect2] = [
	Rect2(), Rect2(), Rect2(), Rect2(),
	Rect2(), Rect2(), Rect2(), Rect2(),
]

@onready var main_screen_vbox: VBoxContainer = $"%MainScreenVBox"
@onready var main_editor_button_hb: HBoxContainer = $"%MainEditorButtonHB"
@onready var plugin_holder: Node = $"%Plugins"
@onready var gui_base: Panel = $"%GuiBase"
@onready var title_bar: HBoxContainer = $"%TitleBar"
@onready var tabbar_panel: PanelContainer = $"%TabbarPanel"
@onready var dock_select_popup: PopupPanel = $"%DockSelectPopup"
@onready var distraction_free_button: Button = $"%DistractionFreeButton"
@onready var scene_root_parent: PanelContainer = $"%SceneRootParent"
@onready var center_split: VSplitContainer = $"%CenterSplit"
@onready var top_split: VSplitContainer = $"%TopSplit"
@onready var launch_pad: PanelContainer = $"%LaunchPad"
@onready var launch_pad_hb: HBoxContainer = $"%LaunchPadHB"
@onready var bottom_panel: PanelContainer = $"%BottomPanel"
@onready var bottom_panel_vb: VBoxContainer = $"%BottomPanelVB"
@onready var bottom_panel_hb: HBoxContainer = $"%BottomPanelHB"
@onready var bottom_panel_hb_editors: HBoxContainer = $"%BottomPanelHBEditors"
@onready var bottom_panel_raise: Button = $"%BottomPanelRaise"
@onready var left_l_hsplit: HSplitContainer = $"%LeftLHSplit"
@onready var left_r_hsplit: HSplitContainer = $"%LeftRHSplit"
@onready var center_hsplit: HSplitContainer = $"%CenterHSplit"
@onready var right_hsplit: HSplitContainer = $"%RightHSplit"
@onready var dock_slots: Array[TabContainer] = [
	$"%DockSlotLeftUL" as TabContainer,
	$"%DockSlotLeftBL" as TabContainer,
	$"%DockSlotLeftUR" as TabContainer,
	$"%DockSlotLeftBR" as TabContainer,
	$"%DockSlotRightUL" as TabContainer,
	$"%DockSlotRightBL" as TabContainer,
	$"%DockSlotRightUR" as TabContainer,
	$"%DockSlotRightBR" as TabContainer,
]
@onready var left_l_vsplit: VSplitContainer = $"%LeftLVSplit"
@onready var left_r_vsplit: VSplitContainer = $"%LeftRVSplit"
@onready var right_l_vsplit: VSplitContainer = $"%RightLVSplit"
@onready var right_r_vsplit: VSplitContainer = $"%RightRVSplit"
@onready var vsplits: Array[VSplitContainer] = [
	left_l_vsplit,
	left_r_vsplit,
	right_l_vsplit,
	right_r_vsplit,
]
@onready var hsplits: Array[HSplitContainer] = [
	left_l_hsplit,
	left_r_hsplit,
	center_hsplit,
	right_hsplit,
]
@onready var main_menu: MenuBar = $"%MainMenu"


func _ready() -> void:
	# Setup needed directories
	if not DirAccess.dir_exists_absolute(interface.get_editor_paths().get_cache_dir()):
		DirAccess.make_dir_recursive_absolute(interface.get_editor_paths().get_cache_dir())
	if not DirAccess.dir_exists_absolute(interface.get_editor_paths().get_config_dir()):
		DirAccess.make_dir_recursive_absolute(interface.get_editor_paths().get_config_dir())
	if not DirAccess.dir_exists_absolute(interface.get_editor_paths().get_data_dir()):
		DirAccess.make_dir_recursive_absolute(interface.get_editor_paths().get_data_dir())
	if not DirAccess.dir_exists_absolute(interface.get_editor_paths().get_project_settings_dir()):
		DirAccess.make_dir_recursive_absolute(interface.get_editor_paths().get_project_settings_dir())

	interface.__base_control = self
	interface.__editor_main_screen_holder = main_screen_vbox
	interface.__select_main_screen_callback = editor_select_by_name
	interface.__set_plugin_enabled_callback = __set_plugin_enabled

	# Load the theme. This could be customized in future.
	theme = preload("res://themes/default_theme.res")

	get_tree().set_auto_accept_quit(false)

	for slot in dock_slots:
		slot.set_custom_minimum_size(Vector2i(170, 0))
		slot.set_v_size_flags(Control.SIZE_EXPAND_FILL)
		slot.set_popup(dock_select_popup)
		slot.pre_popup_pressed.connect(__dock_pre_popup.bind(dock_slots.find(slot)))
		slot.set_drag_to_rearrange_enabled(true)
		slot.set_tabs_rearrange_group(1)
		slot.set_use_hidden_tabs_for_min_size(true)
		slot.tab_selected.connect(__dock_tab_selected.bind(slot))

	bottom_panel_raise.toggled.connect(__bottom_panel_raise_toggled)
	distraction_free_button.pressed.connect(__update_visibility)

	__create_dock_popup()

	__update_visibility()

	propagate_notification(NOTIFICATION_THEME_CHANGED)

	# Load the generated resource pack.
	ProjectSettings.load_resource_pack(
		Env.generated_dir.path_join(Env.resource_pack_name)
	)

	# Load the plugins.
	for cfg in ProjectSettings.get_setting(Env.installed_plugins_key):
		__add_plugin_from_cfg_path(cfg)

	if len(main_editors) > 0:
		editor_select(0)

	__load_docks()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_THEME_CHANGED:
			stylebox_content_no_tabbar = get_theme_stylebox(
				&"PanelForeground",
				&"EditorStyles",
			).duplicate()
			stylebox_content_no_tabbar.set_content_margin_all(0)
			stylebox_content_no_tabbar.set_border_width_all(0)

			if is_instance_valid(gui_base):
				gui_base.add_theme_stylebox_override(
					&"panel",
					get_theme_stylebox(&"Background", &"EditorStyles"),
				)
			if is_instance_valid(tabbar_panel):
				tabbar_panel.add_theme_stylebox_override(
					&"panel",
					get_theme_stylebox(&"tabbar_background", &"TabContainer"),
				)
			if is_instance_valid(distraction_free_button):
				distraction_free_button.icon = get_theme_icon(
					&"DistractionFree",
					&"EditorIcons",
				)
			if is_instance_valid(scene_root_parent):
				if is_instance_valid(tabbar_panel) and tabbar_panel.visible:
					scene_root_parent.add_theme_stylebox_override(
						&"panel",
						get_theme_stylebox(&"Content", &"EditorStyles"),
					)
				else:
					scene_root_parent.add_theme_stylebox_override(
						&"panel",
						stylebox_content_no_tabbar,
					)
			if is_instance_valid(launch_pad):
				launch_pad.add_theme_stylebox_override(
					&"panel",
					get_theme_stylebox(&"LaunchPadNormal", &"EditorStyles")
				)
			if is_instance_valid(bottom_panel):
				bottom_panel.add_theme_stylebox_override(
					&"panel",
					get_theme_stylebox(&"BottomPanel", &"EditorStyles"),
				)
			if is_instance_valid(bottom_panel_raise):
				bottom_panel_raise.icon = get_theme_icon(
					&"ExpandBottomDock", &"EditorIcons",
				)
		NOTIFICATION_WM_CLOSE_REQUEST:
			__save_docks()
			for i in plugin_holder.get_child_count():
				await plugin_holder.get_child(i)._save_external_data()


func add_bottom_panel_item(item: Control, text: String) -> Button:
	var button = Button.new()

	var bip = BottomPanelItem.new()
	bip.button = button
	bip.control = item
	bip.name = text
	bottom_panel_items.append(bip)

	button.flat = true
	button.toggled.connect(__bottom_panel_switch.bind(bip))
	button.text = text
	button.toggle_mode = true
	button.focus_mode = Control.FOCUS_NONE
	bottom_panel_vb.add_child(item)
	bottom_panel_hb.move_to_front()
	bottom_panel_hb_editors.add_child(button)
	item.set_v_size_flags(Control.SIZE_EXPAND_FILL)
	item.hide()

	bottom_panel.show()

	return button


func remove_bottom_panel_item(item: Control) -> void:
	for i in bottom_panel_items:
		if i.control == item:
			if i.control.is_visible_in_tree():
				__bottom_panel_switch(false, i)
			bottom_panel_vb.remove_child(i.control)
			bottom_panel_hb_editors.remove_child(i.button)
			i.button.queue_free()
			bottom_panel_items.erase(i)
			break
	__update_visibility()


func hide_bottom_panel() -> void:
	for i in bottom_panel_items:
		if i.control.is_visible_in_tree():
			__bottom_panel_switch(false, i)


func make_bottom_panel_item_visible(item: Control) -> void:
	for i in bottom_panel_items:
		if i.control == item:
			__bottom_panel_switch(true, i)


func add_control_to_launch_pad(item: Control) -> void:
	launch_pad.show()
	launch_pad_hb.add_child(item)


func remove_control_from_launch_pad(item: Control) -> void:
	launch_pad_hb.remove_child(item)
	if launch_pad_hb.get_child_count() == 0:
		launch_pad.hide()


func add_control_to_dock(slot: int, control: Control):
	dock_slots[slot].add_child(control)
	__update_visibility()


func remove_control_from_dock(control: Control):
	for dock in dock_slots:
		if control.get_parent() == dock:
			dock.remove_child(control)


func add_editor_plugin(plugin) -> void:
	plugin_holder.add_child(plugin)

	if plugin._has_main_screen():
		var tb = Button.new()
		tb.set_flat(true)
		tb.set_toggle_mode(true)
		tb.pressed.connect(editor_select.bind(main_editor_buttons.size()))
		tb.set_name(plugin._get_plugin_name())
		tb.set_text(plugin._get_plugin_name())

		var icon = plugin._get_plugin_icon()
		if is_instance_valid(icon):
			tb.icon = icon
			icon.changed.connect(tb.update_minimum_size)
		elif has_theme_icon(plugin._get_plugin_name(), &"EditorIcons"):
			tb.icon = get_theme_icon(plugin._get_plugin_name(), &"EditorIcons")
		tb.add_theme_font_override(&"font", get_theme_font(&"main_button_font", &"EditorFonts"))
		tb.add_theme_font_size_override(&"font_size", get_theme_font_size(&"main_button_font_size", &"EditorFonts"))

		main_editor_buttons.append(tb)
		main_editor_button_hb.add_child(tb)
		main_editors.append(plugin)

	if plugin.get_script().resource_path not in ProjectSettings.get_setting(Env.enabled_plugins_key):
		plugin._enable_plugin()
		var e = ProjectSettings.get_setting(Env.enabled_plugins_key)
		e.append(plugin.get_script().resource_path)

		var res = ProjectSettings.save_custom(Env.override_settings_path)
		if res != OK:
			prints("Error while saving enabled plugins", res)


func remove_editor_plugin(plugin) -> void:
	plugin._disable_plugin()
	var e = ProjectSettings.get_setting(Env.enabled_plugins_key)
	e.erase(plugin.get_script().resource_path)

	var res = ProjectSettings.save_custom(Env.override_settings_path)
	if res != OK:
		prints("Error while saving enabled plugins", res)

	if plugin._has_main_screen():
		for i in range(-1, len(main_editor_buttons) - 1, -1):
			var bt = main_editor_buttons[i]
			bt.pressed.disconnect(editor_select)
			if bt.text == plugin._get_plugin_name():
				if is_instance_valid(plugin._get_plugin_icon()):
					plugin._get_plugin_icon.changed.disconnect(bt.update_minimum_size)
				main_editor_buttons.erase(bt)
				bt.queue_free()
				break
			else:
				bt.pressed.connect(editor_select.bind(i - 1))

		main_editors.erase(plugin)

	plugin_holder.remove_child(plugin)


func editor_select_by_name(name: String) -> void:
	for i in main_editor_buttons:
		if i.text == name:
			i.pressed.emit()
			break


func editor_select(which: int) -> void:
	if not main_editor_buttons[which].visible:
		return

	for i in len(main_editor_buttons):
		main_editor_buttons[i].set_pressed_no_signal(i == which)

	if current_main_editor == which:
		return

	var editor = main_editors[which]

	if current_main_editor >= 0:
		main_editors[current_main_editor]._make_visible(false)

	main_editors[which]._make_visible(true)
	for p in plugin_holder.get_children():
		p.main_screen_changed.emit(main_editors[which]._get_plugin_name())

	current_main_editor = which


func __set_plugin_enabled(plugin: String, enabled: bool) -> void:
	for node in plugin_holder.get_children():
		if node.get_script().resource_path.get_base_dir().get_file() == plugin:
			if not enabled:
				remove_editor_plugin(node)
			return
	for cfg in ProjectSettings.get_setting(Env.installed_plugins_key):
		if cfg.get_base_dir().get_file() == plugin:
			if enabled:
				__add_plugin_from_cfg_path(cfg)


func __add_plugin_from_cfg_path(path: String):
	var file = ConfigFile.new()
	file.load(path)
	var script: Script = load(
		path.get_base_dir().path_join(file.get_value("plugin", "script")),
	)
	var plg = script.new()
	add_editor_plugin(plg)


func __bottom_panel_switch(enable: bool, item: BottomPanelItem) -> void:
	if item.control.visible == enable:
		return

	if enable:
		for i in bottom_panel_items:
			i.button.set_pressed_no_signal(i == item)
			i.control.set_visible(i == item)
		center_split.dragger_visibility = SplitContainer.DRAGGER_VISIBLE
		center_split.set_collapsed(false)

		bottom_panel_raise.show()
		if bottom_panel_raise.is_pressed():
			top_split.hide()

	else:
		item.control.hide()
		item.button.set_pressed_no_signal(false)
		center_split.dragger_visibility = SplitContainer.DRAGGER_HIDDEN
		center_split.set_collapsed(true)

		bottom_panel_raise.hide()
		if bottom_panel_raise.is_pressed():
			top_split.show()


func __bottom_panel_raise_toggled(pressed: bool) -> void:
	top_split.set_visible(not pressed)


func __dock_tab_selected(tab: int, slot: TabContainer) -> void:
	__update_visibility()


func __create_dock_popup() -> void:
	var dock_vb = VBoxContainer.new()
	dock_select_popup.add_child(dock_vb)

	var dock_hb = HBoxContainer.new()

	dock_tab_move_left = Button.new()
	dock_tab_move_left.flat = true
	dock_tab_move_left.pressed.connect(__dock_move_left)
	if gui_base.is_layout_rtl():
		dock_tab_move_left.icon = get_theme_icon(&"Forward", &"EditorIcons")
	else:
		dock_tab_move_left.icon = get_theme_icon(&"Back", &"EditorIcons")
	dock_tab_move_left.focus_mode = Control.FOCUS_NONE
	dock_hb.add_child(dock_tab_move_left)

	var dock_label = Label.new()
	dock_label.text = tr("Dock Position")
	dock_label.set_h_size_flags(SIZE_EXPAND_FILL)
	dock_label.set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER)
	dock_hb.add_child(dock_label)

	dock_tab_move_right = Button.new()
	dock_tab_move_right.flat = true
	dock_tab_move_right.pressed.connect(__dock_move_right)
	if gui_base.is_layout_rtl():
		dock_tab_move_right.icon = get_theme_icon(&"Back", &"EditorIcons")
	else:
		dock_tab_move_right.icon = get_theme_icon(&"Forward", &"EditorIcons")
	dock_tab_move_right.focus_mode = Control.FOCUS_NONE
	dock_hb.add_child(dock_tab_move_right)

	dock_vb.add_child(dock_hb)

	dock_select = Control.new()
	dock_select.custom_minimum_size = Vector2i(128, 64)
	dock_select.set_v_size_flags(SIZE_EXPAND_FILL)
	dock_select.gui_input.connect(__dock_select_input)
	dock_select.draw.connect(__dock_select_draw)
	dock_select.mouse_exited.connect(__dock_popup_exit)
	dock_vb.add_child(dock_select)

	dock_select_popup.reset_size()


func __dock_pre_popup(which: int) -> void:
	dock_popup_selected_idx = which


func __dock_select_input(event: InputEvent) -> void:
	if event is InputEventMouse:
		var point = event.get_position()

		var nrect: int = -1
		for i in DOCK_SLOT_MAX:
			if dock_select_rects[i].has_point(point):
				nrect = i
				break

		if nrect != dock_select_rect_over_idx:
			dock_select_rect_over_idx = nrect
			dock_select.queue_redraw()

		if nrect == -1:
			return

		if event is InputEventMouseButton:
			if event.get_button_index() == MOUSE_BUTTON_LEFT and event.is_pressed() and dock_popup_selected_idx != nrect:
				var dock: Control = dock_slots[dock_popup_selected_idx].get_current_tab_control()
				if is_instance_valid(dock):
					dock_slots[dock_popup_selected_idx].remove_child(dock)
				if dock_slots[dock_popup_selected_idx].get_tab_count() == 0:
					dock_slots[dock_popup_selected_idx].hide()
				else:
					dock_slots[dock_popup_selected_idx].set_current_tab(0)

				dock_slots[nrect].add_child(dock)
				dock_popup_selected_idx = nrect
				dock_slots[nrect].set_current_tab(dock_slots[nrect].get_tab_count() - 1)
				dock_slots[nrect].show()
				dock_select.queue_redraw()

				__update_visibility()


func __dock_select_draw() -> void:
	var s: Vector2 = dock_select.get_size()
	s.y /= 2.0
	s.x /= 6.0

	var used := Color(0.6, 0.6, 0.6, 0.8)
	var used_selected := Color(0.8, 0.8, 0.8, 0.8)
	var tab_selected := get_theme_color(&"mono_color", &"Editor")
	var unused := used
	unused.a = 0.4
	var unusable := unused
	unusable.a = 0.1

	var unr := Rect2(s.x * 2, 0, s.x * 2, s.y * 2)
	unr.position += Vector2(2, 5)
	unr.size -= Vector2(4, 7)

	dock_select.draw_rect(unr, unusable)

	dock_tab_move_left.disabled = true
	dock_tab_move_right.disabled = true

	if dock_popup_selected_idx != -1 and dock_slots[dock_popup_selected_idx].get_tab_count():
		dock_tab_move_left.disabled = dock_slots[dock_popup_selected_idx].get_current_tab() == 0
		dock_tab_move_right.disabled = dock_slots[dock_popup_selected_idx].get_current_tab() >= dock_slots[dock_popup_selected_idx].get_tab_count() - 1

	for i in DOCK_SLOT_MAX:
		var ofs: Vector2
		match i:
			DOCK_SLOT_LEFT_UL:
				pass
			DOCK_SLOT_LEFT_BL:
				ofs.y += s.y
			DOCK_SLOT_LEFT_UR:
				ofs.x += s.x
			DOCK_SLOT_LEFT_BR:
				ofs += s
			DOCK_SLOT_RIGHT_UL:
				ofs.x += s.x * 4
			DOCK_SLOT_RIGHT_BL:
				ofs.x += s.x * 4
				ofs.y += s.y
			DOCK_SLOT_RIGHT_UR:
				ofs.x += s.x * 4
				ofs.x += s.x
			DOCK_SLOT_RIGHT_BR:
				ofs.x += s.x * 4
				ofs += s
		var r := Rect2(ofs, s)
		dock_select_rects[i] = r
		r.position += Vector2(2, 5)
		r.size -= Vector2(4, 7)

		if i == dock_select_rect_over_idx:
			dock_select.draw_rect(r, used_selected)
		elif dock_slots[i].get_tab_count() == 0:
			dock_select.draw_rect(r, unused)
		else:
			dock_select.draw_rect(r, used)

		for j in min(3, dock_slots[i].get_tab_count()):
			var xofs: int = (r.size.x / 3) * j
			var c := used
			if i == dock_popup_selected_idx and (dock_slots[i].get_current_tab() > 3 or dock_slots[i].get_current_tab() == j):
				c = tab_selected
			dock_select.draw_rect(
				Rect2(2 + ofs.x + xofs, ofs.y, r.size.x / 3 -1, 3), c,
			)


func __dock_move_left() -> void:
	if dock_popup_selected_idx < 0 or dock_popup_selected_idx >= DOCK_SLOT_MAX:
		return
	var current = dock_slots[dock_popup_selected_idx].get_tab_control(dock_slots[dock_popup_selected_idx].get_current_tab())
	var prev = dock_slots[dock_popup_selected_idx].get_tab_control(dock_slots[dock_popup_selected_idx].get_current_tab() - 1)
	if not is_instance_valid(current) or not is_instance_valid(prev):
		return
	dock_slots[dock_popup_selected_idx].move_child(current, prev.get_index())
	#dock_slots[dock_popup_selected_idx].set_current_tab(dock_slots[dock_popup_selected_idx].get_current_tab() - 1)
	dock_select.queue_redraw()
	__save_docks()


func __dock_move_right() -> void:
	var current = dock_slots[dock_popup_selected_idx].get_tab_control(dock_slots[dock_popup_selected_idx].get_current_tab())
	var next = dock_slots[dock_popup_selected_idx].get_tab_control(dock_slots[dock_popup_selected_idx].get_current_tab() + 1)
	if not is_instance_valid(current) or not is_instance_valid(next):
		return
	dock_slots[dock_popup_selected_idx].move_child(next, current.get_index())
	#dock_slots[dock_popup_selected_idx].set_current_tab(dock_slots[dock_popup_selected_idx].get_current_tab() + 1)
	dock_select.queue_redraw()
	__save_docks()


func __save_docks() -> void:
	var config := ConfigFile.new()
	config.load(
		interface.get_editor_paths().get_project_settings_dir()\
		.path_join("editor_layout.cfg")
	)
	__save_docks_to_config(config, "docks")

	for i in plugin_holder.get_child_count():
		plugin_holder.get_child(i)._get_window_layout(config)

	var res = config.save(
		interface.get_editor_paths().get_project_settings_dir()\
		.path_join("editor_layout.cfg")
	)


func __load_docks() -> void:
	var config := ConfigFile.new()
	var err = config.load(
		interface.get_editor_paths().get_project_settings_dir()\
		.path_join("editor_layout.cfg")
	)
	if err != OK:
		return
	__load_docks_from_config(config, "docks")

	for i in plugin_holder.get_child_count():
		plugin_holder.get_child(i)._set_window_layout(config)


func __save_docks_to_config(layout: ConfigFile, section: String) -> void:
	for i in DOCK_SLOT_MAX:
		var names: PackedStringArray = []
		for j in dock_slots[i].get_tab_count():
			names.append(dock_slots[i].get_tab_control(j).get_name())
		var key = "dock_" + str(i + 1)
		if layout.has_section_key(section, key):
			layout.erase_section_key(section, key)
		if len(names) > 0:
			layout.set_value(section, key, ",".join(names))

	for i in len(vsplits):
		if vsplits[i].is_visible_in_tree():
			layout.set_value(
				section,
				"dock_split_" + str(i + 1),
				vsplits[i].get_split_offset(),
			)

	for i in len(hsplits):
		layout.set_value(
			section,
			"dock_hsplit_" + str(i + 1),
			hsplits[i].get_split_offset(),
		)


func __load_docks_from_config(layout: ConfigFile, section: String):
	for i in DOCK_SLOT_MAX:
		if not layout.has_section_key(section, "dock_" + str(i + 1)):
			continue

		var names: PackedStringArray = \
			str(layout.get_value(section, "dock_" + str(i + 1))).split(",")

		for j in len(names):
			var name: String = names[j]
			for k in dock_slots:
				if not k.has_node(name) or not k.get_node(name) is Control:
					continue

				var node = k.get_node(name)

				if dock_slots[i] == k:
					node.move_to_front()
					continue

				k.remove_child(node)
				dock_slots[i].add_child(node)
				dock_slots[i].show()

				break

		if dock_slots[i].get_tab_count():
			dock_slots[i].set_current_tab(0)

	for i in len(vsplits):
		if layout.has_section_key(section, "dock_split_" + str(i + 1)):
			vsplits[i].set_split_offset(layout.get_value(section, "dock_split_" + str(i + 1)))

	for i in len(hsplits):
		if layout.has_section_key(section, "dock_hsplit" + str(i + 1)):
			hsplits[i].set_split_offset(layout.get_value(section, "dock_hsplit" + str(i + 1)))

	__update_visibility()


func __dock_popup_exit() -> void:
	dock_select_rect_over_idx = -1
	dock_select.queue_redraw()


func __update_visibility() -> void:
	# Only show dock slots that have docks.
	var docks_exist = false
	for dock in dock_slots:
		if dock.get_tab_count() != 0:
			docks_exist = true
		if distraction_free_mode or (dock.get_tab_count() == 0 and dock.visible):
			dock.hide()
		elif (dock.get_tab_count() > 0 and not dock.visible):
			dock.show()

	# Only show vsplits with active children.
	for vsplit in vsplits:
		var in_use = (
			vsplit.get_child(0).get_tab_count() > 0
			or vsplit.get_child(1).get_tab_count() > 0
		) and not distraction_free_mode
		if in_use:
			vsplit.show()
		else:
			vsplit.hide()

	# Hide the right hsplit if both children are not shown.
	if right_l_vsplit.visible or right_r_vsplit.visible:
		right_hsplit.show()
	else:
		right_hsplit.hide()

	# Hide distraction free button, if no docks are visible.
	if docks_exist:
		tabbar_panel.show()
		scene_root_parent.add_theme_stylebox_override(
			&"panel",
			get_theme_stylebox(&"Content", &"EditorStyles"),
		)
	else:
		tabbar_panel.hide()
		scene_root_parent.add_theme_stylebox_override(
			&"panel",
			stylebox_content_no_tabbar,
		)

	# Show bottom panel only if bottom panel items exist.
	bottom_panel.visible = len(bottom_panel_items) != 0

	# Hide main window buttons if only one main window is added.
	main_editor_button_hb.visible = len(main_editor_buttons) > 1

