# WebSocket

Godot 4 addon - wrapper node for [`WebSocketPeer`](https://docs.godotengine.org/en/latest/classes/class_websocketpeer.html). It basically restores the "node-based" implementation of WebSockets from Godot 3.X 

## Installation

Clone the repo and copy the `addons/websocket` folder into your project's `addons` folder. Activate the plugin in the project's settings and you're good to go.

## Usage

The `WebSocket` node is a wrapper around a `WebSocketPeer` object, abstracting most of its usage.

Note that, unless specified otherwise, the node will send and receive data as _arrays of bytes_.

### Signals

It provides the following signals:

- `connected(url)`, emitted when the socket successfully connects to `url`
- `connect_failed`, emitted when the socket fails to connect
- `received(data)`, emitted when the socket _is done receiveing_ some data
- `closing`, emitted when the socket starts closing down
- `closed(code, reason)`, emitted when the socket connection is closed; `code` is one of the [standard WebSocket codes](https://www.rfc-editor.org/rfc/rfc6455#section-7.4), and `reason` is a human readable explanation for the closure of the connection

### @export Parameters
```gdscript
@export_range(0, 128) var receive_limit : int = 0        # Max number of packets to receive before emitting received(data) - 0 == no limit
@export_range(0, 300) var connection_timeout : int = 10  # Seconds to wait in the CONNECTING state before declaring the connection failed
@export_group("Routing")
@export var host := "127.0.0.1"  # Hostname to connect to
@export var route := "/"         # URL Route to connect to - a server may serve different websocket connections on different routes
@export var use_WSS := true      # If true, use secure WSS protocol instead of WS - may need to be false for localhost connections
@export_group("Autoconnect")     # See below in Features/Autoconnect
@export var autoconnect_mode := AUTOCONNECT_MODE.NONE
@export var autoconnect_reference : Node = null
```

### Autoconnect

The node can be setup to automatically try connecting when a given node is ready. The options are:

```gdscript
enum AUTOCONNECT_MODE {
	NONE,          # No autoconnect, will need to be connected manually - default
	SELF_READY,    # Autoconnect when the WebSocket node is ready
	PARENT_READY,  # Wait for parent node to be ready (if not null)
	OWNER_READY,   # Wait for owner node to be ready (if not null)
	ROOT_READY,    # Wait for root node to be ready
	CUSTOM,        # Wait for the node specified in autoconnect_reference to be ready (if not null and if not already loaded)
}
```
