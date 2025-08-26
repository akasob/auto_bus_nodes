@icon("../icons/signal_base_node_w.svg") # For dark themes
#@icon("../icons/signal_base_node_b.svg") # For light themes

## Abstract base class for global signal nodes
#@abstract
class_name SignalBase extends Node

## Signal bus through which all the emission will be carried out.
## By default, it is calculated as the root node of SceneTree.
## If you don't need multiple buses, leave this field untouch.
@export var signal_bus: Node:
	get:
		return signal_bus \
			if signal_bus \
			else get_tree().root if is_inside_tree() \
			else Engine.get_main_loop().root


## Remove registered signal and clean up its connections.
func remove_signal(signal_name: StringName) -> void:
	if not signal_name:
		return
	if signal_bus.has_user_signal(signal_name):
		for connection in signal_bus.get_signal_connection_list(signal_name):
			signal_bus.disconnect(signal_name, connection.callable)
		signal_bus.remove_user_signal(signal_name)
		signal_bus.notify_property_list_changed()


# Abstract emulation in waiting for
func _init() -> void:
	assert("Abstract" not in self.to_string(), "Don't instantiate this abstract class")


func _to_string() -> String:
	return "Abstract class SignalBase #%s" % get_instance_id()
