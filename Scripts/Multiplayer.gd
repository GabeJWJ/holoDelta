extends Node2D


var steam = false
var peer
var _hosted_lobby_id = 0
var _joined_lobby_id = 0
@export var player_side: PackedScene
@onready var json = JSON.new()
@onready var ip_prompt = $CanvasLayer/IPPrompt
@onready var chat = $CanvasLayer/Sidebar/ChatWindow/ScrollContainer/Chat
var friendsOnly = 0

var deckInfo
var playmat
var dice

var default_playmat = preload("res://playmat.jpg")
var default_dice = preload("res://diceTexture.png").get_image()

var yourSide
var opponentSide
var possibleSides = {}
var chosen = false
var inGame = false

var yourRPS = -1
var opponentRPS = -1
var yourMulligan = false
var opponentMulligan = false
var yourReady = false
var opponentReady = false

var firstTurn = true
const downloadLocalLink = "https://github.com/GabeJWJ/holoDelta/raw/refs/heads/master/cardLocalization/"
const downloadDBLink = "https://github.com/GabeJWJ/holoDelta/raw/refs/heads/master/cardData.db"
var downloadedDB = false
var downloadedIteration = false
var downloadedLocal = {}
var int_iteration

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	$CanvasLayer/LanguageSelect.get_popup().index_pressed.connect(_on_language_selected)
	$CanvasLayer/SteamHost/MenuButton.get_popup().index_pressed.connect(_on_public_private_chosen)
	$CanvasLayer/InfoButton/Info/VersionText.text += Settings.version
	if !DirAccess.dir_exists_absolute("user://Decks"):
		DirAccess.make_dir_absolute("user://Decks")
		var azki_string = FileAccess.get_file_as_string("res://Decks/starter_azki.json")
		var sora_string = FileAccess.get_file_as_string("res://Decks/starter_sora.json")
		var file_access := FileAccess.open("user://Decks/starter_azki.json", FileAccess.WRITE)
		if not file_access:
			print("An error happened while saving data: ", FileAccess.get_open_error())
			return

		file_access.store_line(azki_string)
		file_access.close()
		file_access = FileAccess.open("user://Decks/starter_sora.json", FileAccess.WRITE)
		if not file_access:
			print("An error happened while saving data: ", FileAccess.get_open_error())
			return

		file_access.store_line(sora_string)
		file_access.close()
	$CanvasLayer/InfoButton/Info/DeckLocationButton/DeckLocation.text += ProjectSettings.globalize_path("user://Decks")
	
	
	$CanvasLayer/Options/OptionBackground/CheckUnrevealed.button_pressed = Settings.settings.AllowUnrevealed
	$CanvasLayer/Options/OptionBackground/AllowProxies.button_pressed = Settings.settings.AllowProxies
	$CanvasLayer/Options/OptionBackground/SFXSlider.value = Settings.settings.SFXVolume
	AudioServer.set_bus_volume_db(Settings.sfx_bus_index, Settings.settings.SFXVolume)
	if Settings.settings.SFXVolume <= -29:
		AudioServer.set_bus_mute(Settings.sfx_bus_index, true)
	else:
		AudioServer.set_bus_mute(Settings.sfx_bus_index, false)
	if Settings.settings.has("Playmat") and Settings.settings.Playmat.size() > 0:
		playmat = Image.new()
		playmat.load_webp_from_buffer(Settings.settings.Playmat)
		playmat.resize(3485,1480)
		$CanvasLayer/PlaymatDiceCustom/ColorRect/TextureRect.texture = ImageTexture.create_from_image(playmat)
	if Settings.settings.has("Dice") and Settings.settings.Dice.size() > 0:
		dice = Image.new()
		dice.load_webp_from_buffer(Settings.settings.Dice)
		$CanvasLayer/PlaymatDiceCustom/ColorRect/SubViewportContainer/SubViewport/Die.new_texture(dice)
	$CanvasLayer/LanguageSelect.text = Settings.get_language()
	$CanvasLayer/Sidebar/InfoPanel.update_word_wrap()
	match Settings.settings.Language:
		"English":
			chat.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		"日本語":
			chat.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	
	var int_iteration_exists = FileAccess.file_exists("user://cardData.db") and DirAccess.dir_exists_absolute("user://cardLocalization") \
	and FileAccess.file_exists("user://cardLocalization/_iteration.txt")
	
	if int_iteration_exists:
		int_iteration = int(FileAccess.get_file_as_string("user://cardLocalization/_iteration.txt"))
		$CanvasLayer/Popup/Label.text = tr("DOWNLOAD_ITER")
		$CanvasLayer/Popup.visible = true
		$HTTPManager.job(downloadLocalLink + "_iteration.txt").on_failure(_iter_failed).on_success(_iter_succeeded).download("user://cardLocalization/_iteration.txt")
	else:
		_download_everything()

func _iter_succeeded(_result):
	if int_iteration != int(FileAccess.get_file_as_string("user://cardLocalization/_iteration.txt")):
		$CanvasLayer/Update/Notification.visible = true
	else:
		$CanvasLayer/Popup.visible = false
		Database._connect()
		Settings._connect_local()

func _iter_failed(_result):
	print(_result)
	$CanvasLayer/Popup/Label.text = tr("DOWNLOAD_ITER_AGAIN")
	$HTTPManager.job(downloadLocalLink + "_iteration.txt").on_failure(_iter_failed).on_success(_iter_succeeded).download("user://cardLocalization/_iteration.txt")

func _download_everything():
	DirAccess.make_dir_absolute("user://cardLocalization")
	$CanvasLayer/Popup/Label.text = tr("DOWNLOADING")
	$CanvasLayer/Popup.visible = true
	$HTTPManager.job(downloadDBLink).on_failure(_download_failed).on_success(_downloaded_db).download("user://cardData.db")
	$HTTPManager.job(downloadLocalLink + "_iteration.txt").on_failure(_download_failed).on_success(_downloaded_iteration).download("user://cardLocalization/_iteration.txt")
	for lang in Settings.languages:
		downloadedLocal[lang[0]] = false
		$HTTPManager.job(downloadLocalLink + "%s.po" % lang[0]).on_failure(_download_failed).on_success(_downloaded_local.bind(lang[0])).download("user://cardLocalization/%s.po" % lang[0])

func _download_failed(_result):
	$CanvasLayer/Popup/Label.text = tr("DOWNLOAD_ERROR")
	_download_everything()

func _downloaded_db(_result):
	downloadedDB = true
	Database._connect()
	if downloadedDB and downloadedIteration and !downloadedLocal.values().has(false):
		$CanvasLayer/Popup.visible = false

func _downloaded_iteration(_result):
	downloadedIteration = true
	if downloadedDB and downloadedIteration and !downloadedLocal.values().has(false):
		$CanvasLayer/Popup.visible = false

func _downloaded_local(_result, lang):
	downloadedLocal[lang] = true
	if !downloadedLocal.values().has(false):
		Settings._connect_local()
	if downloadedDB and downloadedIteration and !downloadedLocal.values().has(false):
		$CanvasLayer/Popup.visible = false

func _download_progress(_assigned_files, _current_files, total_bytes, current_bytes):
	$CanvasLayer/Popup/ProgressBar.max_value = total_bytes
	$CanvasLayer/Popup/ProgressBar.value = current_bytes

func _on_lobby_created(connect, lobby_id):
	_hosted_lobby_id = lobby_id
	
	Steam.setLobbyData(_hosted_lobby_id,"name", Steam.getPersonaName())
	Steam.setLobbyData(_hosted_lobby_id,"game","Holocard")
	Steam.setLobbyData(_hosted_lobby_id, "version", Settings.version)
	Steam.setLobbyData(_hosted_lobby_id, "steamID", str(SteamManager.steam_id))
	Steam.setLobbyData(_hosted_lobby_id, "friendsOnly", str(friendsOnly))
	
	Steam.setLobbyJoinable(_hosted_lobby_id,true)
	
	chosen = true

func _on_host_pressed():
	peer.create_server(25565,1)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_add_player)
	multiplayer.peer_disconnected.connect(_restart)
	_add_player()
	call_deferred("add_child",yourSide,true)
	$CanvasLayer/Host.visible = false
	$CanvasLayer/Join.visible = false
	$CanvasLayer/DeckSelect.visible = false
	$CanvasLayer/DeckList.visible = false
	$CanvasLayer/Title.visible = false
	$"CanvasLayer/Deck Creation".visible = false
	$CanvasLayer/Exit.visible = false
	$CanvasLayer/Options.visible = false
	$CanvasLayer/InfoButton.visible = false
	$CanvasLayer/LanguageSelect.visible = false
	$CanvasLayer/gradient.visible = false
	$CanvasLayer/PlaymatDiceCustom.visible = false
	
	$CanvasLayer/Sidebar.visible = true
	$CanvasLayer/MainMenu.visible = true
	$CanvasLayer/Sidebar/Tabs/Chat.visible = true

func _on_steam_host_pressed():
	peer.create_lobby(SteamMultiplayerPeer.LOBBY_TYPE_PUBLIC,20)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_add_player)
	multiplayer.peer_disconnected.connect(_on_steam_player_disconnect)
	_add_player()
	call_deferred("add_child",yourSide,true)
	
	$CanvasLayer/SteamHost.visible = false
	$CanvasLayer/SteamJoin.visible = false
	$CanvasLayer/DeckSelect.visible = false
	$CanvasLayer/DeckList.visible = false
	$CanvasLayer/Title.visible = false
	$"CanvasLayer/Deck Creation".visible = false
	$CanvasLayer/Exit.visible = false
	$CanvasLayer/Options.visible = false
	$CanvasLayer/InfoButton.visible = false
	$CanvasLayer/LanguageSelect.visible = false
	$CanvasLayer/gradient.visible = false
	$CanvasLayer/PlaymatDiceCustom.visible = false
	
	$CanvasLayer/Sidebar.visible = true
	$CanvasLayer/MainMenu.visible = true
	$CanvasLayer/JoinOptions.visible = true
	$CanvasLayer/Sidebar/Tabs/Chat.visible = true

func _on_public_private_chosen(chosen_index):
	$CanvasLayer/SteamHost/MenuButton.text = $CanvasLayer/SteamHost/MenuButton.get_popup().get_item_text(chosen_index)
	friendsOnly = chosen_index

func _on_steam_join_pressed():
	for lobbyButton in $CanvasLayer/LobbyList/VBoxContainer.get_children():
		lobbyButton.queue_free()
	
	Steam.addRequestLobbyListDistanceFilter(Steam.LOBBY_DISTANCE_FILTER_WORLDWIDE)
	Steam.addRequestLobbyListStringFilter("game","Holocard",Steam.LOBBY_COMPARISON_EQUAL)
	Steam.hasFriend(23,Steam.FRIEND_FLAG_IMMEDIATE)
	Steam.requestLobbyList()
	$CanvasLayer/SteamHost/MenuButton.visible = false

func _on_lobby_match_list(these_lobbies: Array) -> void:
	for this_lobby in these_lobbies:
		# Pull lobby data from Steam, these are specific to our example
		var lobby_name = Steam.getLobbyData(this_lobby, "name")
		var lobby_game = Steam.getLobbyData(this_lobby, "game")
		var lobby_version = Steam.getLobbyData(this_lobby, "version")
		var lobby_host_id = Steam.getLobbyData(this_lobby, "steamID").to_int()
		var lobby_friends_only = bool(Steam.getLobbyData(this_lobby, "friendsOnly").to_int())
		var is_friend = lobby_host_id != 0 and Steam.hasFriend(lobby_host_id,Steam.FRIEND_FLAG_IMMEDIATE)

		# Get the current number of members
		var lobby_num_members: int = Steam.getNumLobbyMembers(this_lobby)
		
		if lobby_game != "Holocard":
			print("other spacewar lobby found")
			continue

		# Create a button for the lobby
		var lobbyButton = Button.new()
		lobbyButton.text = lobby_name
		if lobby_version == Settings.version:
			lobbyButton.pressed.connect(_join_steam_lobby.bind(this_lobby))
		else:
			lobbyButton.text += " " + tr("VERSION_MISMATCH")
			#lobbyButton.pressed.connect(_join_steam_lobby.bind(this_lobby))
			lobbyButton.disabled = true
		if is_friend or !lobby_friends_only:
			$CanvasLayer/LobbyList/VBoxContainer.add_child(lobbyButton)
		
		if is_friend:
			$CanvasLayer/LobbyList/VBoxContainer.move_child(lobbyButton,0)
	
	$CanvasLayer/LobbyList.visible = true
	$CanvasLayer/CancelLobby.visible = true

"""
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
				print(lobby)
				print(Steam.getAllLobbyData(lobby))
				if Steam.getLobbyData(lobby, "version") == Settings.version:
					lobbyButton.pressed.connect(_join_steam_lobby.bind(lobby))
				else:
					lobbyButton.text += " vm" #" (Version mismatch)"
					lobbyButton.pressed.connect(_join_steam_lobby.bind(lobby))
					#lobbyButton.disabled = true
				$CanvasLayer/LobbyList/VBoxContainer.add_child(lobbyButton)
	
	$CanvasLayer/LobbyList.visible = true
	$CanvasLayer/CancelLobby.visible = true
"""

func _add_player(id=1):
	var side = player_side.instantiate()
	side.name = str(id)
	side.set_multiplayer_authority(id)
	if id == 1:
		yourSide = side
		yourSide.ended_turn.connect(_on_end_turn)
		yourSide.made_turn_choice.connect(_on_your_choice_made)
		yourSide.rps.connect(_your_rps)
		yourSide.mulligan_done.connect(_your_mulligan)
		yourSide.ready_decided.connect(_your_ready)
		yourSide.sent_game_message.connect(_on_side_gave_game_message)
	else:
		possibleSides[id] = side

@rpc("authority","call_remote","reliable")
func _connect_turn_buttons(side_id):
	var side = get_node(str(side_id))
	side.ended_turn.connect(_on_opponent_end_turn)
	side.made_turn_choice.connect(_on_opponent_choice_made)
	side.rps.connect(_your_rps)
	side.mulligan_done.connect(_your_mulligan)
	side.ready_decided.connect(_your_ready)
	side.sent_game_message.connect(_on_side_gave_game_message)

@rpc("any_peer","call_remote","reliable")
func _start(opponent_id, deck_json, playmat_buffer, dice_buffer):
	opponentSide = possibleSides[opponent_id]
	
	Steam.setLobbyJoinable(_hosted_lobby_id,false)
	for possible_id in possibleSides:
		if possible_id != opponent_id and possible_id != 1:
			possibleSides[possible_id].queue_free()
			print(possible_id)
			_close_lobby.rpc_id(possible_id)
	
	json.parse(deck_json)
	opponentSide.oshi = json.data.oshi
	opponentSide.deckList = json.data.deck
	opponentSide.cheerDeckList = json.data.cheerDeck
	if json.data.has("sleeve"):
		opponentSide.mainSleeve = json.data.sleeve
	if json.data.has("cheerSleeve"):
		opponentSide.cheerSleeve = json.data.cheerSleeve
	if json.data.has("oshiSleeve"):
		opponentSide.oshiSleeve = json.data.oshiSleeve
	if playmat_buffer:
		opponentSide.playmatBuffer = playmat_buffer
	if dice_buffer:
		opponentSide.diceBuffer = dice_buffer
	
	add_child(opponentSide)
	set_chosen.rpc_id(opponent_id)
	_connect_turn_buttons.rpc(opponentSide.name)
	yourSide.specialStart()
	opponentSide.call_deferred("_start")
	call_deferred("connect_info",1)
	call_deferred("connect_info",opponent_id)
	
	$CanvasLayer/JoinOptions.visible = false
	inGame = true

@rpc("any_peer","call_remote","reliable")
func set_chosen():
	chosen = true
	$CanvasLayer/Sidebar/Tabs/Chat.visible = true
	$CanvasLayer/JoinWait.visible = false
	yourSide = get_node(str(multiplayer.get_unique_id()))
	opponentSide = get_node("1")

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

func _your_mulligan():
	if multiplayer.get_unique_id() == 1:
		yourMulligan = true
		if opponentMulligan:
			_all_mulligan()
	else:
		_opponent_mulligan.rpc()

@rpc("any_peer","call_remote","reliable")
func _opponent_mulligan():
	opponentMulligan = true
	if yourMulligan:
		_all_mulligan()

func _all_mulligan():
	yourSide.specialStart3()
	opponentSide.specialStart3.rpc()

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
	yourSide.specialStart4()
	opponentSide.specialStart4.rpc()
	_enable_steps.rpc()

func _please_add_join_option():
	var playmat_buffer
	if playmat:
		playmat_buffer = playmat.save_webp_to_buffer(true,0.6)
	var dice_buffer
	if dice:
		dice_buffer = dice.save_webp_to_buffer(true,0.4)
	_add_join_option.rpc_id(1,Steam.getPersonaName(),JSON.stringify(deckInfo),playmat_buffer,dice_buffer)

@rpc("any_peer","call_remote","reliable")
func _add_join_option(steam_name, deck_json, playmat_buffer, dice_buffer):
	var opponent_id = multiplayer.get_remote_sender_id()
	var newJoinButton = Button.new()
	newJoinButton.name = str(multiplayer.get_remote_sender_id())
	newJoinButton.text = steam_name
	newJoinButton.pressed.connect(_start.bind(opponent_id, deck_json, playmat_buffer, dice_buffer))
	$CanvasLayer/JoinOptions/ScrollContainer/VBoxContainer.add_child(newJoinButton)

func _please_start():
	var playmat_buffer
	if playmat:
		playmat_buffer = playmat.save_webp_to_buffer(true)
	var dice_buffer
	if dice:
		dice_buffer = dice.save_webp_to_buffer(true)
	_start.rpc(multiplayer.get_unique_id(), JSON.stringify(deckInfo), playmat_buffer, dice_buffer)

func _on_join_pressed():
	peer = ENetMultiplayerPeer.new()
	ip_prompt.visible = true
	ip_prompt.get_node("LineEdit").grab_focus()
	$CanvasLayer/Host.visible = false
	$CanvasLayer/Join.visible = false
	$CanvasLayer/CancelIPJoin.visible = true

func _join_steam_lobby(lobby_id):
	peer.connect_lobby(lobby_id)
	_joined_lobby_id = lobby_id
	multiplayer.multiplayer_peer = peer
	multiplayer.connected_to_server.connect(_please_add_join_option)
	multiplayer.server_disconnected.connect(_restart)
	rotation = -3.141
	$Camera2D.position = Vector2(670,-644)
	$CanvasLayer/SteamHost.visible = false
	$CanvasLayer/SteamJoin.visible = false
	$CanvasLayer/DeckSelect.visible = false
	$CanvasLayer/DeckList.visible = false
	$CanvasLayer/LobbyList.visible = false
	$CanvasLayer/Title.visible = false
	$"CanvasLayer/Deck Creation".visible = false
	$CanvasLayer/CancelLobby.visible = false
	$CanvasLayer/Exit.visible = false
	$CanvasLayer/Options.visible = false
	$CanvasLayer/InfoButton.visible = false
	$CanvasLayer/LanguageSelect.visible = false
	$CanvasLayer/gradient.visible = false
	$CanvasLayer/PlaymatDiceCustom.visible = false
	
	$CanvasLayer/Sidebar.visible = true
	$CanvasLayer/MainMenu.visible = true
	$CanvasLayer/JoinWait.visible = true

func _on_line_edit_text_submitted(new_text):
	ip_prompt.visible = false
	if new_text == "":
		new_text = ip_prompt.get_node("LineEdit").placeholder_text
	peer.create_client(new_text,25565)
	multiplayer.multiplayer_peer = peer
	multiplayer.connected_to_server.connect(_please_start)
	multiplayer.server_disconnected.connect(_restart)
	rotation = -3.141
	$Camera2D.position = Vector2(670,-644)
	$CanvasLayer/DeckSelect.visible = false
	$CanvasLayer/DeckList.visible = false
	$CanvasLayer/Title.visible = false
	$"CanvasLayer/Deck Creation".visible = false
	$CanvasLayer/CancelIPJoin.visible = false
	$CanvasLayer/Exit.visible = false
	$CanvasLayer/Options.visible = false
	$CanvasLayer/InfoButton.visible = false
	$CanvasLayer/LanguageSelect.visible = false
	$CanvasLayer/gradient.visible = false
	$CanvasLayer/PlaymatDiceCustom.visible = false
	
	$CanvasLayer/Sidebar.visible = true
	$CanvasLayer/MainMenu.visible = true

func connect_info(side_id):
	connect_info_all.rpc(side_id)

@rpc("call_local","reliable")
func connect_info_all(side_id):
	var side = get_node(str(side_id))
	side.card_info_set.connect(update_info)
	side.card_info_clear.connect(clear_info)


func update_info(topCard, card):
	$CanvasLayer/Sidebar/InfoPanel._new_info(topCard, card)

func clear_info():
	$CanvasLayer/Sidebar/InfoPanel._clear_showing()


func _restart(id=null):
	if get_tree():
		get_tree().reload_current_scene()

func _on_steam_player_disconnect(id=0):
	if opponentSide and id == opponentSide.name.to_int():
		_restart()
	elif inGame == false and $CanvasLayer/JoinOptions/ScrollContainer/VBoxContainer.has_node(str(id)):
		$CanvasLayer/JoinOptions/ScrollContainer/VBoxContainer.get_node(str(id)).queue_free()


func _on_steam_connect_pressed():
	$"CanvasLayer/Steam Connect".visible = false
	$"CanvasLayer/Direct Connect".visible = false
	peer = SteamMultiplayerPeer.new()
	peer.lobby_created.connect(_on_lobby_created)
	Steam.lobby_match_list.connect(_on_lobby_match_list)
	steam = true
	var connected = SteamManager.initialize_steam()
	if connected != null:
		$CanvasLayer/Popup/Label.text = str(connected)
		$CanvasLayer/Popup.visible = true
	else:
		$CanvasLayer/SteamHost.visible = true
		$CanvasLayer/SteamJoin.visible = true
		$CanvasLayer/SteamHost/MenuButton.visible = true


func _on_direct_connect_pressed():
	$"CanvasLayer/Steam Connect".visible = false
	$"CanvasLayer/Direct Connect".visible = false
	$CanvasLayer/Host.visible = true
	$CanvasLayer/Join.visible = true
	peer = ENetMultiplayerPeer.new()

@rpc("any_peer","call_remote","reliable")
func _on_end_turn(fromOpponent = false):
	if firstTurn:
		_enable_steps.rpc(true)
		firstTurn = false
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

func _on_deck_select_pressed():
	$CanvasLayer/DeckList._all_decks()
	$CanvasLayer/DeckList.visible = true

func _hide_deck_list():
	$CanvasLayer/DeckList.visible = false

func _on_deck_list_selected(deckJSON):
	deckInfo = deckJSON
	$CanvasLayer/DeckSelect.text = deckInfo.deckName
	$"CanvasLayer/Steam Connect".disabled = false
	$"CanvasLayer/Direct Connect".disabled = false
	_hide_deck_list()


func _on_cancel_lobby_pressed():
	$CanvasLayer/LobbyList.visible = false
	$CanvasLayer/CancelLobby.visible = false
	$CanvasLayer/SteamHost/MenuButton.visible = true

func _on_cancel_ip_join_pressed():
	ip_prompt.visible = false
	ip_prompt.get_node("LineEdit").release_focus()
	$CanvasLayer/Host.visible = true
	$CanvasLayer/Join.visible = true
	$CanvasLayer/CancelIPJoin.visible = false

func _on_exit_pressed():
	if steam and chosen:
		_close_lobby.rpc()
	get_tree().quit()

func _on_main_menu_pressed():
	$CanvasLayer/MainMenu/Confirmation.visible = true

func _on_no_pressed():
	$CanvasLayer/MainMenu/Confirmation.visible = false

@rpc("any_peer","call_remote","reliable")
func _close_lobby():
	if _hosted_lobby_id != 0:
		_restart()
	if _joined_lobby_id != 0:
		peer.close()
		Steam.leaveLobby(_joined_lobby_id)

func _on_yes_pressed():
	if steam:
		peer.close()
		Steam.leaveLobby(_joined_lobby_id)
		
		if chosen:
			_close_lobby.rpc()
		
		_restart()
	else:
		if multiplayer.is_server():
			for i in multiplayer.get_peers():
				multiplayer.multiplayer_peer.disconnect_peer(i)
			_restart()
		else:
			multiplayer.multiplayer_peer.disconnect_peer(1)
			_restart()


func _on_options_pressed():
	$CanvasLayer/Options/OptionBackground.visible = !$CanvasLayer/Options/OptionBackground.visible


func _on_check_unrevealed_pressed():
	Settings.update_settings("AllowUnrevealed",$CanvasLayer/Options/OptionBackground/CheckUnrevealed.button_pressed)

func _on_allow_proxies_pressed():
	Settings.update_settings("AllowProxies",$CanvasLayer/Options/OptionBackground/AllowProxies.button_pressed)

func _on_language_selected(index_selected):
	Settings.update_settings("Language",Settings.languages[index_selected][0])
	$CanvasLayer/LanguageSelect.text = Settings.languages[index_selected][1]
	$CanvasLayer/Sidebar/InfoPanel.update_word_wrap()
	match Settings.settings.Language:
		"en":
			chat.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		"ja":
			chat.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY


func _on_info_button_pressed():
	$CanvasLayer/InfoButton/Info.visible = !$CanvasLayer/InfoButton/Info.visible

func _on_deck_location_button_pressed():
	$CanvasLayer/InfoButton/Info/DeckLocationButton/DeckLocation.visible = !$CanvasLayer/InfoButton/Info/DeckLocationButton/DeckLocation.visible

func _on_card_info_pressed():
	$CanvasLayer/Sidebar/ChatWindow.visible = false
	$CanvasLayer/Sidebar/OptionsWindow.visible = false
	
	$CanvasLayer/Sidebar/Tabs/Chat.button_pressed = false
	$CanvasLayer/Sidebar/Tabs/Options.button_pressed = false
	
	$CanvasLayer/Sidebar/InfoPanel.visible = true

func _on_chat_pressed():
	$CanvasLayer/Sidebar/InfoPanel.visible = false
	$CanvasLayer/Sidebar/OptionsWindow.visible = false
	
	$CanvasLayer/Sidebar/Tabs/CardInfo.button_pressed = false
	$CanvasLayer/Sidebar/Tabs/Options.button_pressed = false
	
	$CanvasLayer/Sidebar/ChatWindow.visible = true
	$CanvasLayer/Sidebar/Tabs/Chat/Notification.visible = false

func _on_sidebar_options_pressed():
	$CanvasLayer/Sidebar/InfoPanel.visible = false
	$CanvasLayer/Sidebar/ChatWindow.visible = false
	
	$CanvasLayer/Sidebar/Tabs/CardInfo.button_pressed = false
	$CanvasLayer/Sidebar/Tabs/Chat.button_pressed = false
	
	$CanvasLayer/Sidebar/OptionsWindow.visible = true


@rpc("any_peer","call_local","reliable")
func send_message_rpc(message):
	if multiplayer.get_remote_sender_id() == multiplayer.get_unique_id():
		chat.text += "\n\n" + tr("YOU") + ": "
	else:
		chat.text += "\n\n" + tr("OPPONENT") + ": "
	chat.text += message
	$CanvasLayer/Sidebar/ChatWindow/ScrollContainer.scroll_vertical = $CanvasLayer/Sidebar/ChatWindow/ScrollContainer.get_v_scroll_bar().max_value
	if !$CanvasLayer/Sidebar/ChatWindow.visible:
		$CanvasLayer/Sidebar/Tabs/Chat/Notification.visible = true

func send_message(message):
	if message != "":
		send_message_rpc.rpc(message)
		$CanvasLayer/Sidebar/ChatWindow/ToSend.text = ""

func send_message_on_click():
	send_message($CanvasLayer/Sidebar/ChatWindow/ToSend.text)

@rpc("any_peer","call_local","reliable")
func game_message(message):
	if multiplayer.get_remote_sender_id() == multiplayer.get_unique_id():
		chat.text += "\n" +message.format({person = tr("YOU")})
	else:
		chat.text += "\n" +message.format({person = tr("OPPONENT")})
	
	$CanvasLayer/Sidebar/ChatWindow/ScrollContainer.scroll_vertical = $CanvasLayer/Sidebar/ChatWindow/ScrollContainer.get_v_scroll_bar().max_value

func _on_side_gave_game_message(message):
	game_message.rpc(message)


func _on_sfx_slider_drag_ended(value_changed=null):
	$CanvasLayer/Options/OptionBackground/SFXSlider/Test.play()


func _on_sfx_slider_value_changed(value):
	AudioServer.set_bus_volume_db(Settings.sfx_bus_index, value)
	Settings.update_settings("SFXVolume", value)
	if value <= -29:
		AudioServer.set_bus_mute(Settings.sfx_bus_index, true)
	else:
		AudioServer.set_bus_mute(Settings.sfx_bus_index, false)


func _on_playmat_dice_custom_pressed():
	$CanvasLayer/PlaymatDiceCustom/ColorRect.visible = true

func _on_cosmetics_exit_pressed():
	$CanvasLayer/PlaymatDiceCustom/ColorRect.visible = false

func _on_playmat_pressed():
	$CanvasLayer/PlaymatDiceCustom/ColorRect/Playmat/LoadDialog.visible = true

func _on_dice_pressed():
	$CanvasLayer/PlaymatDiceCustom/ColorRect/Dice/LoadDialog.visible = true

func _on_playmat_load_dialog_file_selected(path):
	playmat = Image.load_from_file(path)
	playmat.resize(3485,1480)
	$CanvasLayer/PlaymatDiceCustom/ColorRect/TextureRect.texture = ImageTexture.create_from_image(playmat)
	Settings.update_settings("Playmat",Array(playmat.save_webp_to_buffer(true)))

func _on_dice_load_dialog_file_selected(path):
	dice = Image.load_from_file(path)
	$CanvasLayer/PlaymatDiceCustom/ColorRect/SubViewportContainer/SubViewport/Die.new_texture(dice)
	Settings.update_settings("Dice",Array(dice.save_webp_to_buffer(true)))


func _on_playmat_default_pressed():
	playmat = null
	$CanvasLayer/PlaymatDiceCustom/ColorRect/TextureRect.texture = default_playmat
	Settings.update_settings("Playmat",null)


func _on_dice_default_pressed():
	dice = null
	$CanvasLayer/PlaymatDiceCustom/ColorRect/SubViewportContainer/SubViewport/Die.new_texture(default_dice)
	Settings.update_settings("Dice",null)


func _on_hide_cosmetics_toggled(toggled_on):
	if toggled_on:
		opponentSide._hide_cosmetics()
	else:
		opponentSide._redo_cosmetics()

@rpc("any_peer","call_local","reliable")
func _select_step(step_id):
	for stepButton in $CanvasLayer/Sidebar/Steps.get_children():
		if stepButton.name.contains(str(step_id)):
			stepButton.set_pressed_no_signal(true)
		else:
			stepButton.set_pressed_no_signal(false)
	yourSide.step = step_id

func _on_step_pressed(toggle_on, step_id):
	$CanvasLayer/Sidebar/Steps.get_node("Step" + str(step_id)).set_pressed_no_signal(!toggle_on)
	if !yourSide.is_turn:
		return
	_select_step.rpc(step_id)

@rpc("any_peer","call_local","reliable")
func _enable_steps(allow_performance = false):
	for stepButton in $CanvasLayer/Sidebar/Steps.get_children():
		if stepButton.name.contains("5"):
			stepButton.disabled = !allow_performance
		else:
			stepButton.disabled = false

func _steps_enabled():
	for stepButton in $CanvasLayer/Sidebar/Steps.get_children():
		if !stepButton.disabled:
			return true
	return false

func _next_step():
	var result = yourSide.step + 1
	if result == 5 and $CanvasLayer/Sidebar/Steps/Step5.disabled:
		result = 6
	return result

func _last_step():
	var result = yourSide.step - 1
	if result == 0:
		result = 1
	elif result == 5 and $CanvasLayer/Sidebar/Steps/Step5.disabled:
		result = 4
	return result

func _unhandled_key_input(event):
	if yourSide != null:
		if event.is_action_pressed("SwapPanels"):
			if $CanvasLayer/Sidebar/ChatWindow.visible:
				_on_card_info_pressed()
			elif $CanvasLayer/Sidebar/InfoPanel.visible:
				_on_chat_pressed()
		if yourSide.is_turn and _steps_enabled():
			if event.is_action_pressed("Next Step"):
				var newStep = _next_step()
				if newStep == 7:
					yourSide.end_turn()
				else:
					_select_step.rpc(newStep)
			elif event.is_action_pressed("Last Step"):
				var newStep = _last_step()
				_select_step.rpc(newStep)
