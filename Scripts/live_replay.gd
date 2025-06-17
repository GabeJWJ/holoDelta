extends Node

var tcp : TCPServer
var clients := []

func _ready():
	if OS.has_feature("web"):
		print("Web version doesn't support Third Party Application Integration")
		pass
	tcp = TCPServer.new()
	#test
	open_connection(Settings.settings["ThirdPartyAPIPort"])
	
func _process(_delta):
	# accept new connections
	if tcp.is_connection_available():
		var client = tcp.take_connection()
		if client:
			client.set_no_delay(true)
			clients.append(client)
			print("New client connected")
			
	# handle exisitng clients
	for client : StreamPeerTCP in clients:
		if client.get_available_bytes() > 0:
			var data = client.get_utf8_string(client.get_available_bytes())
			print("📨 Received:", data)
			
			# Currently specified as /live-replay endpoint
			_handle_request(client, data)	
			
func _generate_replay_data():
	return {
		"timeElapsed": ReplayData.time_elapsed,
		"winner": ReplayData.winner,
		"winReason": ReplayData.win_reason,
		"currentState": ReplayData.current_game_state,
		"recentlyPlayedCard": ReplayData.recently_played_card,
		"players": [
			{
				"side": "top",
				"hp": ReplayData.top_side_hp,
				"life": ReplayData.top_side_life,
				"deckCount": ReplayData.top_side_deck_count
			},
			{
				"side": "bottom",
				"hp": ReplayData.bottom_side_hp,
				"life": ReplayData.bottom_side_life,
				"deckCount": ReplayData.bottom_side_deck_count
			}
		],
		"events": ReplayData.events
	}	
			
func _handle_request(client, data):
	var request_line = data.split("\r\n")[0]  # e.g., "GET /hello HTTP/1.1"
	var path = request_line.split(" ")[1]     # extract "/hello"
	
	match path:
		"/live-replay":
			_send_response(client, _generate_replay_data())
		_:
			_send_response(client, {"error": "Not found"}, 404)
		
func _send_response(client, data, status_code = 200, content_type: String = "application/json"):
	# Build JSON response
		var response = data
		var string_res = JSON.stringify(response)
		var json := _generate_http_response(string_res, status_code, content_type)
		# Sent as UTF8 buffer
		client.put_data(json.to_utf8_buffer())	
			
func _generate_http_response(body: String, status_code: int = 200, content_type: String = "application/json") -> String:
	var status_text = {
		200: "OK",
		404: "Not Found",
		500: "Internal Server Error"
	}.get(status_code, "OK")
	# Headers
	var headers = "HTTP/1.1 %d %s\r\n" % [status_code, status_text]
	headers += "Content-Length: %d\r\n" % body.to_utf8_buffer().size()
	headers += "Content-Type: %s%s\r\n" % [content_type, "; charset=utf-8" if content_type == "application/json" else ""]
	headers += "Connection: keep-alive\r\n"
	headers += "Server: holoDelta/godot_4.3\r\n"
	headers += "Date: %s\r\n" % _get_http_date()
	headers += "\r\n"
	return headers + body
	
func _get_http_date():
	# Get the current time in UTC
	var datetime = Time.get_datetime_dict_from_system(true) # true for UTC
	
	# Map day of week (0=Sunday, 1=Monday, ..., 6=Saturday)
	var days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
	var day_name = days[datetime.weekday]
	
	# Map month (1=January, ..., 12=December)
	var months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
	var month_name = months[datetime.month - 1]
	
	# Format the date string: "Day, DD Mon YYYY HH:MM:SS GMT"
	var formatted_date = "%s, %02d %s %04d %02d:%02d:%02d GMT" % [
		day_name,
		datetime.day,
		month_name,
		datetime.year,
		datetime.hour,
		datetime.minute,
		datetime.second
	]
	
	return formatted_date
			
func open_connection(port: int):
	tcp.listen(port)
	
