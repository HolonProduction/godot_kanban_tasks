extends Object

## Allows the registration of anonymous singletons into the scene tree.


const HOLDER_NAME: String = "PluginSingletons"
const PLUGIN_SINGLETON_META_NAME: String = "plugin_singleton"


static func __get_holder(requester: Node) -> Node:
	var holder: Node = requester.get_tree().get_root().get_node_or_null(HOLDER_NAME)
	if not is_instance_valid(holder):
		holder = Node.new()
		holder.name = HOLDER_NAME
		requester.get_tree().get_root().add_child(holder)

	return holder


static func __get_singleton(holder: Node, p_script: Script, requester: Node) -> Variant:
	for child in holder.get_children():
		if child.get_script() == p_script:
			return child
	return null
	

static func instance_of(p_script: Script, requester: Node) -> Variant:
	var holder := __get_holder(requester)
	
	var instance = __get_singleton(holder, p_script, requester)
	if instance == null:
		instance = p_script.new()
		holder.add_child(instance)
	return instance


static func __set_plugin(plugin: Node):
	var holder := __get_holder(plugin)
	holder.set_meta(PLUGIN_SINGLETON_META_NAME, plugin)


static func get_plugin(requester: Node) -> Node:
	var holder := __get_holder(requester)
	if holder.has_meta(PLUGIN_SINGLETON_META_NAME):
		return holder.get_meta(PLUGIN_SINGLETON_META_NAME)
	else:
		return null
	
