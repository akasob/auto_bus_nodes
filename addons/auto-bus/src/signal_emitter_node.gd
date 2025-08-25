## Node for emitting global signals using global bus
@icon("../icons/SignalNode.svg")
class_name SignalEmitter extends SignalBaseNode

## Name of signal has been to register for emitting.
## If this empty we use this node standard name.
@export var emit_to : StringName = &"":
	get:
		return emit_to if emit_to else name


## Used to emit the signal.
func emit(args = []) -> void:
	signal_bus.emit_signal(emit_to, args)


## Fast create instance, register, emit signal and return instance for later use.
static func create(signal_name: StringName, args = [], bus: Node = null) -> SignalEmitter:
	var result: SignalEmitter = SignalEmitter.new()
	result.emit_to = signal_name
	if bus: result.signal_bus = bus
	result._setup()
	result.emit(args)
	return result


## Emit signal, register if not present, but not save a emitter
static func fire(signal_name: StringName, args = [], bus: Node = null) -> void:
	create(signal_name, args, bus).queue_free()


func _setup() -> void:
	if not signal_bus.has_user_signal(emit_to):
		signal_bus.add_user_signal(emit_to)
		signal_bus.notify_property_list_changed()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_ENTER_TREE:
			_setup()
