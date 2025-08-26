@icon("../icons/signal_receiver_node_w.svg") # For dark themes
#@icon("../icons/signal_receiver_node_b.svg") # For light themes

## Receiving global signals via some predefined bus node
class_name SignalReceiver
extends SignalBase

## Name of the signal to react. If this empty, Receiver uses own name.
@export var react_to : StringName = &"":
	get:
		return react_to if react_to else name

var _is_registered := false 

## Emitted when the signal of 'react_to' is received.
signal react(parameter)


## Private callback for internally emit react signal
func _react_func(parameter) -> void: react.emit(parameter)


## Configure node and return self to chaining.
func configure(signal_name: StringName, custom_bus: Node = null) -> SignalReceiver:
	react_to = signal_name
	if custom_bus:
		signal_bus = custom_bus
	return self


## Attach given callback for reacting and return self to chaining.
func attach(callback: Callable, flags: int = 0) -> SignalReceiver:
	react.connect(callback, flags)
	return self


## Register new Receiver and place them to given bus as a internal child.
static func register(signal_name: StringName, callback: Callable, custom_bus: Node = null) -> void:
	var new_receiver := SignalReceiver.create(signal_name, callback, custom_bus)
	new_receiver.name = "%s_receiver_%s" % [signal_name, new_receiver.get_instance_id()]
	new_receiver.signal_bus.add_child.call_deferred(new_receiver, true, Node.INTERNAL_MODE_FRONT)
	if not new_receiver.signal_bus.is_inside_tree():
		# Notify Receiver as READY because setup don't work at this point
		new_receiver.notification(NOTIFICATION_READY)


## Create new instance of Receiver and return created instance for later use.
static func create(signal_name: StringName, callback: Callable, custom_bus: Node = null) -> SignalReceiver:
	var result = SignalReceiver.new().configure(signal_name, custom_bus).attach(callback)
	return result


## Remove disconnected Receivers for given bus.
## This function returns count of nodes to be queued for freeng.
static func cleanup(bus: Node) -> int:
	if not bus:
		return 0
	var cleanup_counter : int = 0
	for node in bus.get_children(true):
		if node is SignalReceiver:
			if not node.react.get_connections():
				cleanup_counter += 1
				node.queue_free()
	return cleanup_counter


## Subscribe (connect) configured callback to bus signal.
func _subscribe() -> void:
	if signal_bus.has_user_signal(react_to) \
	and not signal_bus.is_connected(react_to, _react_func):
		_is_registered = true
		signal_bus.connect(react_to, _react_func)


## Unsubscribe (disconnect) any subscriptions (connections).
func _unsubscribe() -> void:
	# At first we disconnect all callables connected to inner signal
	# to free them (especially if they are anonymous lambdas)
	for connection in react.get_connections():
		react.disconnect(connection.callable)
	# Then we disconnect this instance from bus
	if signal_bus.has_user_signal(react_to) \
	and signal_bus.is_connected(react_to, _react_func):
		signal_bus.disconnect(react_to, _react_func)


func _notification(what: int) -> void:
	match what: 
		# Receivers setting up after Emitters and Registers
		NOTIFICATION_ENTER_TREE:
			pass # Don't setup here
		NOTIFICATION_READY:
			if not _is_registered:
				# _is_registered becomes true later in _subscribe()
				signal_bus.property_list_changed.connect(_subscribe)
			_subscribe()
		NOTIFICATION_EXIT_TREE:
			_unsubscribe()


func _to_string() -> String:
	var result := "%s:" % name if name else ""
	result += "<SignalReceiver#%s>" % get_instance_id()
	return result
