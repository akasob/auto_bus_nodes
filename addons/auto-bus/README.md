# Auto-Bus
## Description
The purpose of the plugin is to dynamically create global signals on shared signal bus (event bus) without the need to create a singleton to manage it.

The plugin adds 3 nodes:
+ SignalEmitter <- a node representing a signal emitter, where the 'emit_to' property is the signal's name.
+ SignalReceiver <- a node representing a signal receiver, where the 'react_to' property is the name of the signal it expects to receive.
+ SignalRegister <- a node representing a signal registrator, where the 'signals' property is the list of signals to be registered on bus.

To quickly test classes, place this code in your _ready():
```gdscript
SignalReceiver.register("test", print) # immediately creates and registers global signal
await get_tree().process_frame # wait a frame, because some operations processes deferred
SignalEmitter.fire("test", "test ok") # this prints that, and works everywhere
```
