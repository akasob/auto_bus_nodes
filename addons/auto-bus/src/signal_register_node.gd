@icon("../icons/signal_bulk_register_node_w.svg") # For dark themes
#@icon("../icons/signal_bulk_register_node_b.svg") # For light themes

## Bulk register node for organising signal bus or other purposes.
class_name SignalRegister
extends SignalBase

## List of signals which to be registered.
@export var signals: Array[StringName]


## Register all defined signals.
func _setup() -> void:
	if not signals:
		return
	for item in signals:
		if not signal_bus.has_user_signal(item):
			signal_bus.add_user_signal(item)
	signal_bus.notify_property_list_changed()


func _notification(what: int) -> void:
	match what:
		# Registers must setup signals before Receivers
		NOTIFICATION_ENTER_TREE:
			_setup()
		NOTIFICATION_READY:
			pass # Don't setup here

func _to_string() -> String:
	var result := "%s:" % name if name else ""
	result += "<SignalRegister#%s>" % get_instance_id()
	return result
