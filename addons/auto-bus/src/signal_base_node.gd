class_name SignalBaseNode extends Node

## Node for acting like a bus, by default we use the root node
@export var signal_bus: Node:
	get:
		return signal_bus if signal_bus else Engine.get_main_loop().root
