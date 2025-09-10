@icon("../icons/signal_emitter_node_w.svg") # For dark themes
#@icon("../icons/signal_emitter_node_b.svg") # For light themes

## Emitting global signals via some predefined bus node
class_name SignalEmitter
extends SignalBase

class EmitCancelationToken: pass

## The name of the signal to emit. If this empty, Emitter uses own name.
@export var emit_to : StringName = &"":
	get:
		return emit_to if emit_to else name


## Configure node and return self to chaining.
func configure(signal_name: StringName, custom_bus: Node = null) -> SignalEmitter:
	emit_to = signal_name
	if custom_bus:
		if custom_bus != signal_bus:
			_unset()
			signal_bus = custom_bus
	_setup()
	return self


## Emit the signal with given parameter and return self to chaining.
func emit(parameter = []) -> SignalEmitter:
	signal_bus.emit_signal(emit_to, parameter)
	return self

## Create new instance of Emitter, immediately emit signal and queuing instance to free.
static func fire(signal_name: StringName, parameter = [], custom_bus: Node = null) -> void:
	SignalEmitter.create(signal_name, parameter, custom_bus).queue_free()

## Create new instance of Emitter, optionally emit its signal and return created instance for later use.
static func create(signal_name: StringName, parameter = EmitCancelationToken.new(), custom_bus: Node = null) -> SignalEmitter:
	var result := SignalEmitter.new().configure(signal_name, custom_bus)
	# cancellation via passing a null or false is not suitable
	# because we want to have ability to emit signal with
	# null or bool as parameter that's why we use empty inner class
	var cancel := parameter is EmitCancelationToken
	return result if cancel else result.emit(parameter)


## Setup bus by adding configured user signal to it.
func _setup() -> void:
	if not signal_bus.has_user_signal(emit_to):
		signal_bus.add_user_signal(emit_to)
		signal_bus.notify_property_list_changed()


func _unset() -> void:
	if signal_bus.has_user_signal(emit_to):
		signal_bus.remove_user_signal(emit_to)
		signal_bus.notify_property_list_changed()


func _notification(what) -> void: 
	match what:
		# Emitters setting up before Receivers
		NOTIFICATION_ENTER_TREE:
			_setup()
		NOTIFICATION_READY:
			pass # Don't setup here


func _to_string() -> String:
	var result := "%s:" % name if name else ""
	result += "<SignalEmitter#%s>" % get_instance_id()
	return result
