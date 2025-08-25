@icon("../icons/SignalReceptor.svg")
class_name SignalReceiver extends SignalBaseNode

## The name of the signal to react to.
## If this empty we use this node standard name.
@export var react_to : StringName = &"":
	get:
		return react_to if react_to else name

## Emitted when the signal of 'react_to' is received
signal react(args)

func on_react(args) -> void:
	react.emit(args)

## Create the instance, subscribe with given callback, store as a child of given bus (/root if not) and return reference for later use.
static func register(signal_name: StringName, callback: Callable, bus: Node = null) -> SignalReceiver:
	var result: SignalReceiver = SignalReceiver.new()
	if bus: result.signal_bus = bus
	result.react_to = signal_name
	result.react.connect(callback)
	result.signal_bus.add_child.call_deferred(result)
	return result


func _subscribe() -> void:
	if signal_bus.has_user_signal(react_to) and not signal_bus.is_connected(react_to, on_react):
		signal_bus.connect(react_to, on_react)


func _unsubscribe() -> void:
	if signal_bus.has_user_signal(react_to) and signal_bus.is_connected(react_to, on_react):
		signal_bus.disconnect(react_to, on_react)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_ENTER_TREE:
			pass
		NOTIFICATION_READY:
			signal_bus.property_list_changed.connect(_subscribe)
			_subscribe()
		NOTIFICATION_EXIT_TREE:
			_unsubscribe()
