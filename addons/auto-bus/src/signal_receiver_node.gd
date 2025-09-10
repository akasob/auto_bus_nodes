@icon("../icons/signal_receiver_node_w.svg") # For dark themes
#@icon("../icons/signal_receiver_node_b.svg") # For light themes

## Receiving global signals via some predefined bus node
class_name SignalReceiver
extends SignalBase

## Name of the signal to react. If this empty, Receiver uses own name.
@export var react_to : StringName = &"":
	get:
		return react_to if react_to else name
	set(v):
		if v != react_to:
			_unsubscribe()
			react_to = v
			_subscribe()

#var _is_registered := false 

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
	_set_rcv_name(new_receiver)
	_add_rcv_to_bus(new_receiver, new_receiver.signal_bus)
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


## Get disconnected Receivers list for given bus.
## This function returns list of nodes to be used for pooling.
static func get_orphans(bus: Node) -> Array[SignalReceiver]:
	if not bus:
		return []
	var result : Array[SignalReceiver]
	for node in bus.get_children(true):
		if node is SignalReceiver:
			if not node.react.get_connections():
				result.append(node)
	return result


## Get first disconnected Receiver on given bus.
## If bus have no Receivers, create and return new one.
static func get_first_orphan(bus: Node = null) -> SignalReceiver:
	var result := SignalReceiver.new()
	if not bus:
		bus = result.signal_bus
	for node in bus.get_children(true):
		if node is SignalReceiver:
			if not node.react.get_connections():
				result.queue_free()
				return node
	_set_rcv_name(result)
	_add_rcv_to_bus(result, bus)
	#bus.add_child.call_deferred(result, true, Node.INTERNAL_MODE_BACK)
	return result.configure(&"_rename_me_", bus)


static func _set_rcv_name(receiver: SignalReceiver) -> void:
	if not receiver.name:
		receiver.name = &"auto"
	receiver.name = "%s_receiver_%s" % [receiver.react_to, receiver.get_instance_id()]


static func _add_rcv_to_bus(receiver: SignalReceiver, bus: Node) -> void:
	bus.add_child.call_deferred(receiver, true, Node.INTERNAL_MODE_BACK)


## Subscribe (connect) configured callback to bus signal.
func _subscribe() -> void:
	if signal_bus.has_user_signal(react_to) \
	and not signal_bus.is_connected(react_to, _react_func):
		signal_bus.connect(react_to, _react_func)
		#_is_registered = true


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
		#_is_registered = false


func _notification(what: int) -> void:
	match what: 
		# Receivers setting up after Emitters and Registers
		NOTIFICATION_ENTER_TREE:
			pass # Don't setup here
		NOTIFICATION_READY:
			if not signal_bus.property_list_changed.is_connected(_subscribe):
				signal_bus.property_list_changed.connect(_subscribe)
			_subscribe()
		NOTIFICATION_EXIT_TREE:
			_unsubscribe()


func _to_string() -> String:
	var result := "%s:" % name if name else ""
	result += "<SignalReceiver#%s>" % get_instance_id()
	return result
