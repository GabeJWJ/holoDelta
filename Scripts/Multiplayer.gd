extends Node2D


var steam = false
var peer
var _hosted_lobby_id = 0
@export var player_side: PackedScene
@onready var json = JSON.new()
@onready var ip_prompt= $CanvasLayer/IPPrompt

var deckInfo
var possibleDecks = []

var yourSide
var opponentSide

var yourRPS = -1
var opponentRPS = -1

var yourReady = false
var opponentReady = false

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	$CanvasLayer/MenuButton.get_popup().index_pressed.connect(_set_deck_info)
	var path
	if !OS.has_feature("editor"):
		path = OS.get_executable_path().get_base_dir() + "/Decks"
	else:
		path = "res://Decks"
	var dir = DirAccess.open(path)
	if dir:
		for file_name in dir.get_files():
			if json.parse(FileAccess.get_file_as_string(path + "/" + file_name)) == 0:
				possibleDecks.append(json.data)
				$CanvasLayer/MenuButton.get_popup().add_item(json.data.deckName)
	else:
		print("An error occurred when trying to access the path.")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _set_deck_info(set_to_index):
	deckInfo = possibleDecks[set_to_index]
	$CanvasLayer/MenuButton.text = deckInfo.deckName
	$"CanvasLayer/Steam Connect".disabled = false
	$"CanvasLayer/Direct Connect".disabled = false

func _on_lobby_created(connect, lobby_id):
	_hosted_lobby_id = lobby_id
	
	Steam.setLobbyJoinable(_hosted_lobby_id,true)
	
	Steam.setLobbyData(_hosted_lobby_id,"name","Holocard")

func _on_host_pressed():
	peer.create_server(25565,1)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_add_player)
	multiplayer.peer_disconnected.connect(_restart)
	_add_player()
	call_deferred("add_child",yourSide,true)
	#yourSide.oshi = deckInfo.oshi
	#yourSide.deckList = deckInfo.deck
	#yourSide.cheerDeckList = deckInfo.cheerDeck
	$CanvasLayer/Host.visible = false
	$CanvasLayer/Join.visible = false
	$CanvasLayer/MenuButton.visible = false
	$CanvasLayer/Info.visible = true
	$CanvasLayer/Title.visible = false
	$"CanvasLayer/Deck Creation".visible = false

func _on_steam_host_pressed():
	peer.create_lobby(SteamMultiplayerPeer.LOBBY_TYPE_FRIENDS_ONLY,2)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_add_player)
	multiplayer.peer_disconnected.connect(_restart)
	_add_player()
	call_deferred("add_child",yourSide,true)
	#yourSide.oshi = deckInfo.oshi
	#yourSide.deckList = deckInfo.deck
	#yourSide.cheerDeckList = deckInfo.cheerDeck
	$CanvasLayer/SteamHost.visible = false
	$CanvasLayer/SteamJoin.visible = false
	$CanvasLayer/MenuButton.visible = false
	$CanvasLayer/Info.visible = true
	$CanvasLayer/Title.visible = false
	$"CanvasLayer/Deck Creation".visible = false


func _on_steam_join_pressed():
	for i in range(0, Steam.getFriendCount()):
		var steam_id: int = Steam.getFriendByIndex(i, Steam.FRIEND_FLAG_IMMEDIATE)
		var game_info: Dictionary = Steam.getFriendGamePlayed(steam_id)

		if game_info.is_empty():
		# This friend is not playing a game
			continue
		else:
		# They are playing a game, check if it's the same game as ours
			var app_id: int = game_info['id']
			var lobby = game_info['lobby']
			if app_id != SteamManager.steam_app_id or lobby is String:
			# Either not in this game, or not in a lobby
				continue
			else:
				var lobbyButton = Button.new()
				lobbyButton.text = Steam.getFriendPersonaName(steam_id)
				lobbyButton.pressed.connect(_join_steam_lobby.bind(lobby))
				$CanvasLayer/LobbyList/VBoxContainer.add_child(lobbyButton)
	
	$CanvasLayer/LobbyList.visible = true
	$CanvasLayer/CancelLobby.visible = true

func _add_player(id=1):
	var side = player_side.instantiate()
	side.name = str(id)
	side.set_multiplayer_authority(id)
	side.entered_list.connect(_on_list_enter)
	side.exited_list.connect(_on_list_exit)
	if id == 1:
		yourSide = side
		yourSide.ended_turn.connect(_on_end_turn)
		yourSide.made_turn_choice.connect(_on_your_choice_made)
		yourSide.rps.connect(_your_rps)
		yourSide.ready_decided.connect(_your_ready)
	else:
		opponentSide = side

@rpc("authority","call_remote","reliable")
func _connect_turn_buttons(side_id):
	var side = get_node(str(side_id))
	side.ended_turn.connect(_on_opponent_end_turn)
	side.made_turn_choice.connect(_on_opponent_choice_made)
	side.rps.connect(_your_rps)
	side.ready_decided.connect(_your_ready)

@rpc("any_peer","call_remote","reliable")
func _start(deck_json):
	
	json.parse(deck_json)
	opponentSide.oshi = json.data.oshi
	opponentSide.deckList = json.data.deck
	opponentSide.cheerDeckList = json.data.cheerDeck
	
	add_child(opponentSide)
	_connect_turn_buttons.rpc(opponentSide.name)
	var id = multiplayer.get_remote_sender_id()
	yourSide.specialStart()
	opponentSide.call_deferred("_start")
	call_deferred("connect_info",1)
	call_deferred("connect_info",id)

func _your_rps(choice):
	if multiplayer.get_unique_id() == 1:
		yourRPS = choice
		if opponentRPS != -1:
			_rps_decide()
	else:
		_opponent_rps.rpc(choice)

@rpc("any_peer","call_remote","reliable")
func _opponent_rps(choice):
	opponentRPS = choice
	if yourRPS != -1:
		_rps_decide()

func _rps_decide():
	if yourRPS == opponentRPS:
		yourSide.specialRestart()
		opponentSide.specialRestart.rpc()
		yourRPS = -1
		opponentRPS = -1
	elif yourRPS - opponentRPS in [-2,1]:
		#You won
		yourSide.rps_end()
		opponentSide.rps_end.rpc()
		yourSide._show_turn_choice()
	else:
		yourSide.rps_end()
		opponentSide.rps_end.rpc()
		opponentSide._show_turn_choice.rpc()

func _your_ready():
	if multiplayer.get_unique_id() == 1:
		yourReady = true
		if opponentReady:
			_all_ready()
	else:
		_opponent_ready.rpc()

@rpc("any_peer","call_remote","reliable")
func _opponent_ready():
	opponentReady = true
	if yourReady:
		_all_ready()

func _all_ready():
	yourSide.specialStart3()
	opponentSide.specialStart3.rpc()

func _please_start():
	_start.rpc(JSON.stringify(deckInfo))

func _on_join_pressed():
	peer = ENetMultiplayerPeer.new()
	ip_prompt.visible = true
	ip_prompt.get_node("LineEdit").grab_focus()
	$CanvasLayer/Host.visible = false
	$CanvasLayer/Join.visible = false
	$CanvasLayer/CancelIPJoin.visible = true

func _join_steam_lobby(lobby_id):
	peer.connect_lobby(lobby_id)
	multiplayer.multiplayer_peer = peer
	multiplayer.connected_to_server.connect(_please_start)
	multiplayer.server_disconnected.connect(_restart)
	rotation = -3.141
	$Camera2D.position = Vector2(0,-1044)
	$CanvasLayer/SteamHost.visible = false
	$CanvasLayer/SteamJoin.visible = false
	$CanvasLayer/MenuButton.visible = false
	$CanvasLayer/LobbyList.visible = false
	$CanvasLayer/Info.visible = true
	$CanvasLayer/Title.visible = false
	$"CanvasLayer/Deck Creation".visible = false
	$CanvasLayer/CancelLobby.visible = false

func _on_line_edit_text_submitted(new_text):
	ip_prompt.visible = false
	if new_text == "":
		new_text = ip_prompt.get_node("LineEdit").placeholder_text
	peer.create_client(new_text,25565)
	multiplayer.multiplayer_peer = peer
	multiplayer.connected_to_server.connect(_please_start)
	multiplayer.server_disconnected.connect(_restart)
	rotation = -3.141
	$Camera2D.position = Vector2(0,-1044)
	$CanvasLayer/MenuButton.visible = false
	$CanvasLayer/Info.visible = true
	$CanvasLayer/Title.visible = false
	$"CanvasLayer/Deck Creation".visible = false
	$CanvasLayer/CancelIPJoin.visible = false

func connect_info(side_id):
	connect_info_all.rpc(side_id)

@rpc("call_local","reliable")
func connect_info_all(side_id):
	var side = get_node(str(side_id))
	side.card_info_set.connect(update_info)
	side.card_info_clear.connect(clear_info)


func _on_list_enter():
	$Camera2D.canGo = false

func _on_list_exit():
	$Camera2D.canGo = true


func update_info(card_num, desc, art_data):
	$CanvasLayer/Info/Preview.texture = art_data
	$CanvasLayer/Info/CardText.text = desc

func clear_info():
	$CanvasLayer/Info/Preview.texture = load("res://cardbutton.png")
	$CanvasLayer/Info/CardText.text = ""


func _restart(id=null):
	get_tree().reload_current_scene()


func _on_steam_connect_pressed():
	$"CanvasLayer/Steam Connect".visible = false
	$"CanvasLayer/Direct Connect".visible = false
	$CanvasLayer/SteamHost.visible = true
	$CanvasLayer/SteamJoin.visible = true
	peer = SteamMultiplayerPeer.new()
	peer.lobby_created.connect(_on_lobby_created)
	steam = true
	SteamManager.initialize_steam()


func _on_direct_connect_pressed():
	$"CanvasLayer/Steam Connect".visible = false
	$"CanvasLayer/Direct Connect".visible = false
	$CanvasLayer/Host.visible = true
	$CanvasLayer/Join.visible = true
	peer = ENetMultiplayerPeer.new()

@rpc("any_peer","call_remote","reliable")
func _on_your_choice_made(choice):
	yourSide.set_player1.rpc(choice)
	yourSide.set_is_turn.rpc(choice)
	opponentSide.set_player1.rpc(!choice)
	opponentSide.set_is_turn.rpc(!choice)
	yourSide.specialStart2()
	opponentSide.specialStart2.rpc()

func _on_opponent_choice_made(choice):
	_on_your_choice_made.rpc(!choice)

@rpc("any_peer","call_remote","reliable")
func _on_end_turn(fromOpponent = false):
	if fromOpponent:
		yourSide.set_is_turn.rpc(true)
		opponentSide.set_is_turn.rpc(false)
	else:
		yourSide.set_is_turn.rpc(false)
		opponentSide.set_is_turn.rpc(true)

func _on_opponent_end_turn():
	_on_end_turn.rpc(true)


func _on_deck_creation_pressed():
	get_tree().change_scene_to_file("res://Scenes/deck_creation.tscn")


func _on_cancel_lobby_pressed():
	$CanvasLayer/LobbyList.visible = false
	$CanvasLayer/CancelLobby.visible = false

func _on_cancel_ip_join_pressed():
	ip_prompt.visible = false
	ip_prompt.get_node("LineEdit").release_focus()
	$CanvasLayer/Host.visible = true
	$CanvasLayer/Join.visible = true
	$CanvasLayer/CancelIPJoin.visible = false
