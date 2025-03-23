extends Node

enum AUTOCONNECT_MODE {
	NONE,
	SELF_READY,
	PARENT_READY,
	OWNER_READY,
	ROOT_READY,
	CUSTOM,
}

signal connected(url)
signal connect_failed
signal received(data)
signal closing
signal closed(code, reason)

@export_range(0, 128) var receive_limit : int = 0
@export_range(0, 300) var connection_timeout : int = 10
@export_group("Routing")
@export var host := "127.0.0.1"
@export var route := "/"
@export var use_WSS := true
@export_group("Autoconnect")
@export var autoconnect_mode := AUTOCONNECT_MODE.NONE
@export var autoconnect_reference : Node = null

var full_url := ""

var socket := WebSocketPeer.new()
var buffer : PackedByteArray = []
var last_sent : PackedByteArray = []
var last_received : PackedByteArray = []
var received_count := 0
var _rc := 0
var socket_state:
	get:
		socket.poll()
		return socket.get_ready_state()
var connect_timedout : bool :
	get:
		return connect_timer.is_stopped() and connection_timeout > 0
var socket_connected := false
var closing_started := false

var connect_timer := Timer.new()

func _ready():
	add_child(connect_timer)
	connect_timer.one_shot = true
	
	if autoconnect_mode != AUTOCONNECT_MODE.NONE:
		match autoconnect_mode:
			AUTOCONNECT_MODE.PARENT_READY:
				var par = get_parent()
				if par != null:
					await par.ready
			AUTOCONNECT_MODE.OWNER_READY:
				if owner != null:
					await owner.ready
			AUTOCONNECT_MODE.ROOT_READY:
				await get_tree().root.ready
			AUTOCONNECT_MODE.CUSTOM:
				var ar = autoconnect_reference
				if ar != null and ar.get_parent() == null:
					await ar.ready
			AUTOCONNECT_MODE.SELF_READY:
				pass
		
		connect_socket()
		

func connect_socket(h = host, r = route):
	if socket_connected:
		push_error("Can't connect a socket already in use!")
		return false
	
	connect_timer.start(connection_timeout)
	set_process(true)
	
	host = h
	var protocol = "wss" if use_WSS else "ws"
	full_url = "%s://%s/%s" % [protocol, host, route.trim_prefix("/")]

	var err = socket.connect_to_url(full_url)
	if err != OK: # or socket_state != WebSocketPeer.STATE_OPEN:
		push_error("Unable to connect socket! (tried connecting to %s)" % [full_url])
		return false
	
	return true
	
# Receive ALL available packets
func receive():
	if not check_open():
		return
	
	buffer = []
	while socket.get_available_packet_count():
		buffer.append_array(socket.get_packet())
		
	return buffer
	
func send_dict(dict_to_send: Dictionary):
	var s : String = JSON.stringify(dict_to_send)
	send_string(s)
	
func send_string(str_to_send : String):
	send(str_to_send.to_ascii_buffer())

# Send bytes
func send(to_send : PackedByteArray):
	if not check_open():
		return
	
	last_sent = to_send.duplicate()
	socket.put_packet(to_send)
	
func check_open():
	if not socket_connected:
		push_error("Socket not connected yet!")
		return false
	if closing_started:
		push_error("Socket has closed/is closing!")
		return false
		
	return true
	
func _process(delta):
	socket.poll()
	
	match socket_state:
		WebSocketPeer.STATE_CONNECTING:
			if connect_timedout:
				socket.close(1001, "Connection timeout")
				connect_failed.emit()
		WebSocketPeer.STATE_OPEN:
			if not socket_connected:
				socket_connected = true
				closing_started = false
				connect_timer.stop()
				connected.emit(full_url)
			
			var available = socket.get_available_packet_count()
			var enable_receive = (receive_limit == 0 or (_rc < receive_limit))
			
			if available > 0 and enable_receive:
				buffer.append_array(socket.get_packet())
				_rc += 1
			elif len(buffer) > 0:
				last_received = buffer.duplicate()
				received_count = _rc
				received.emit(last_received)
				_rc = 0
				buffer.clear()
		WebSocketPeer.STATE_CLOSING:
			if not closing_started:
				closing.emit()
		WebSocketPeer.STATE_CLOSED:
			var code = socket.get_close_code()
			var reason = socket.get_close_reason()
			closed.emit(code, reason)
			set_process(false)
