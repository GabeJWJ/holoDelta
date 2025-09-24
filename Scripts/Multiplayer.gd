extends Node2D


@export var player_side: PackedScene
@onready var json = JSON.new()
@onready var chat = %Chat

var deckInfo

var playmat
var dice
var default_playmat = preload("res://playmat.jpg")
var default_dice = preload("res://diceTexture.png").get_image()

var yourSide
var opponentSide
@export var player_id : String
@export var player_name : String

var gameToSpectate
var spectatedSides = {}

var inGame = false
var rps = false

#Lobby stuff
@onready var lobby_banlist = %LobbyBanlist
@onready var lobby_private = %LobbyPrivateButton
@onready var lobby_spectators = %LobbySpectatorButton
@onready var lobby_list = %LobbyPanel
@onready var lobby_list_found = %LobbiesFound
@onready var lobby_list_searching_text = %LobbyListSearchingText
@onready var lobby_list_code = %LobbyListCode
@onready var lobby_list_code_button = %JoinByCode
# I renamed a lot of the game list UI components to spectate list for my own clarity
# I will leave all the variable names the same though
@onready var game_list = %SpectatePanel
@onready var game_list_found = %GamesFound
@onready var game_list_searching_text = %SpectateListSearchingText
@onready var game_list_code = %SpectateListCode
@onready var game_list_code_button = %SpectateByCode
@onready var lobby_host_name = %HostName
@onready var lobby_host_options = %HostOptions
@onready var lobby_host_ready = %LobbyHostReady
@onready var lobby_host_ready_text = %HostReadyLabel
@onready var lobby_host_deck_select = %HostDeckSelect
@onready var lobby_chosen_name = $CanvasLayer/LobbyScreen/HBoxContainer/VBoxContainer/HBoxContainer2/JoinName
@onready var lobby_chosen_options = $CanvasLayer/LobbyScreen/HBoxContainer/VBoxContainer/CenterContainer2/JoinOptions
@onready var lobby_chosen_ready = $CanvasLayer/LobbyScreen/HBoxContainer/VBoxContainer/CenterContainer2/JoinOptions/Ready
@onready var lobby_chosen_ready_text = $CanvasLayer/LobbyScreen/HBoxContainer/VBoxContainer/HBoxContainer2/Ready
@onready var lobby_chosen_deck_select = $CanvasLayer/LobbyScreen/HBoxContainer/VBoxContainer/CenterContainer2/JoinOptions/DeckSelect
@onready var lobby_waiting = $CanvasLayer/LobbyScreen/HBoxContainer/VBoxContainer2/ScrollContainer/VBoxContainer
@onready var lobby_code = $CanvasLayer/LobbyScreen/HBoxContainer/VBoxContainer2/LobbyCode
@onready var lobby_game_start = $CanvasLayer/LobbyScreen/HBoxContainer/VBoxContainer2/HBoxContainer/StartGame
@onready var lobby_deckerror = $CanvasLayer/LobbyScreen/DeckErrors
@onready var lobby_deckerrorlist = $CanvasLayer/LobbyScreen/DeckErrors/ScrollContainer/Label
@onready var player_count = %PlayerCount
@onready var lobby_join_button = %LobbyJoin
@onready var spectate_button = %GameSpectate
var current_lobby = null
var lobby_you_are_host = false

var packet_number = -1
var proper_hypertext

# Stolen from https://forum.godotengine.org/t/how-do-you-get-all-nodes-of-a-certain-class/9143/2
func findByClass(node: Node, className : String, result : Array) -> void:
	if node.is_class(className) :
		result.push_back(node)
	for child in node.get_children():
		findByClass(child, className, result)

# Called when the node enters the scene tree for the first time.
func _ready():
	proper_hypertext = "https://" if $WebSocket.use_WSS else "http://"
	$WebSocket.host = Server.websocketURL
	
	randomize()
	
	#Intialize Decks folder and starter decks
	if !DirAccess.dir_exists_absolute("user://Decks"):
		DirAccess.make_dir_absolute("user://Decks")
		
	var dir = DirAccess.open("res://Decks")
	var temp_loaded_decks = Settings.settings.LoadedDecks.duplicate()
	for file_name in dir.get_files():
		if file_name not in Settings.settings.LoadedDecks:
			var deck_string = FileAccess.get_file_as_string("res://Decks/" + file_name)
			var file_access = FileAccess.open("user://Decks/" + file_name, FileAccess.WRITE)
			if not file_access:
				print("An error happened while saving data: ", FileAccess.get_open_error())
				return
			file_access.store_line(deck_string)
			file_access.close()
			temp_loaded_decks.append(file_name)
	Settings.update_settings("LoadedDecks", temp_loaded_decks)
	
	#Connect PopupMenus
	%LanguageSelect.get_popup().index_pressed.connect(_on_language_selected)
	
	#Initialize settings
	%CheckUnrevealed.button_pressed = Settings.settings.AllowUnrevealed
	%AllowProxies.button_pressed = Settings.settings.AllowProxies
	%AllowProxies.disabled = !Settings.settings.UseCardLanguage
	%AllowProxies.modulate.a = 0.5 if !Settings.settings.UseCardLanguage else 1
	%UseCardLanguage.button_pressed = Settings.settings.UseCardLanguage
	%OnlyEN.button_pressed = Settings.settings.OnlyEN
	
	%SFXSlider.value = Settings.settings.SFXVolume
	%SFXSlider.value = Settings.settings.SFXVolume
	AudioServer.set_bus_volume_db(Settings.sfx_bus_index, Settings.settings.SFXVolume)
	if Settings.settings.SFXVolume <= -29:
		AudioServer.set_bus_mute(Settings.sfx_bus_index, true)
	else:
		AudioServer.set_bus_mute(Settings.sfx_bus_index, false)
	%BGMSlider.value = Settings.settings.BGMVolume
	%BGMSlider.value = Settings.settings.BGMVolume
	AudioServer.set_bus_volume_db(Settings.bgm_bus_index, Settings.settings.BGMVolume)
	if Settings.settings.BGMVolume < -39:
		AudioServer.set_bus_mute(Settings.bgm_bus_index, true)
	else:
		AudioServer.set_bus_mute(Settings.bgm_bus_index, false)
	
	if Settings.settings.has("Playmat") and Settings.settings.Playmat.size() > 0:
		playmat = Image.new()
		playmat.load_webp_from_buffer(Settings.settings.Playmat)
		playmat.resize(3485,1480)
		%PlaymatTextureRect.texture = ImageTexture.create_from_image(playmat)
	if Settings.settings.has("Dice") and Settings.settings.Dice.size() > 0:
		dice = Image.new()
		dice.load_webp_from_buffer(Settings.settings.Dice)
		%Die.new_texture(dice)
	
	%LanguageSelect.text = Settings.get_language()
	%InfoPanel.update_word_wrap()
	match Settings.settings.Language:
		"en", "es", "fr", "ko", "vi":
			chat.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		"ja":
			chat.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	
	#Setup Info
	if Database.setup:
		%CardVersionText.text += Settings.card_version
	else:
		%Popup.visible = true
		%DownloadLabel.text = tr("DOWNLOAD_CARDS")
		
		if OS.has_feature("editor") or (OS.has_feature("web") or OS.get_name() == "Web"):
			#The web version (and editor) have the card data built-in
			#Because it can update all the time
			_start_data()
		elif FileAccess.file_exists("user://cardData.zip"):
			#If we have the card archive we just load it in
			_attempt_load_zip()
		else:
			#If not we NEED to download it - game does not work without it.
			_attempt_download_zip()
		
	
	#Visual
	%ClientVersionText.text += Settings.client_version
	%DeckLocation.text += ProjectSettings.globalize_path("user://Decks")
	
	%LobbiesFoundLabel.text = tr("LOBBY_PUBLIC_LOBBIES_FOUND").format({"amount": "0"})
	%SpectateFoundLabel.text = tr("LOBBY_PUBLIC_LOBBIES_FOUND").format({"amount": "0"})
	
	fix_font_size()
	
	#Automatic deck import
	# => This will only run in HTML5 env and when query parameter: imported_deck
	# exists
	if (OS.has_feature("web") or OS.get_name() == "Web") and not GameState.deck_processed:
		# get the DOM window object -> cast as godot object
		var window = JavaScriptBridge.get_interface("window")
		var console = JavaScriptBridge.get_interface("console")
		# get the query strings
		var query_string = window.location.search
		if (query_string):
			# parse the query strings
			var params = WebUtils.parse_query_string(query_string)
			#if contains the imported deck => execute needed action
			if (params.has("imported_deck")):
				var converted_deck = _parse_deck_code(params["imported_deck"], OS.is_debug_build())
				if converted_deck != null:
					# Load the deck to game state
					GameState.deck_to_import = converted_deck
					%ConfirmDialog.set_yes_button_disabled(true)
					%ConfirmDialog.visible = true
					%ConfirmDialog.dialogTitle = tr("DECK_AUTOLOAD_CONFIRM")
					%ConfirmDialog.dialogContent = tr("DECK_AUTOLOAD_CONFIRM_INFO")
					%ConfirmDialog.confirmed.connect(_on_deck_import_confirmed)
					%ConfirmDialog.cancelled.connect(_on_deck_import_cancelled)

func _on_deck_import_cancelled():
	# Cancel the deck import process also
	# means finishing the deck import process
	GameState.deck_processed = true
	# empty the deck
	GameState.deck_to_import = null
	
func _on_deck_import_confirmed():
	# Reuse code to switch to deck creation scene
	_on_deck_creation_pressed()
				
# Variant: Whether Dictionary or null
# Convert from base64 string to JSON string, then convert to dictionary
func _parse_deck_code(deck_data: String, allow_log: bool=false) -> Variant:
	#Gabe's change: It should use base64url instead, but Godot can't natively decode that
	#So we'll need to convert it
	deck_data = deck_data.replace("-","+").replace("_","/")
	var true_length = ceili(deck_data.length() / 4.0) * 4
	deck_data = deck_data.rpad(true_length, "=")
	
	var console = JavaScriptBridge.get_interface("console")
	var json_deck = Marshalls.base64_to_utf8(deck_data)
	if allow_log:
		console.log("DECODED: " +json_deck)
	if json_deck != null and json_deck != "":
		var parsed_json = JSON.parse_string(json_deck)
		if parsed_json == null:
			if allow_log:
				console.log("FAILED TO PARSE JSON. SKIPPED")
			return null
		else:
			return parsed_json
	else:
		if allow_log:
			console.log("FAILED TO GET DECODED BASE 64. SKIPPED")
		return null

func update_info(topCard, card):
	%InfoPanel._new_info(topCard, card)

func clear_info():
	%InfoPanel._clear_showing()

func _restart(id=null):
	if get_tree():
		get_tree().reload_current_scene()

func _on_exit_pressed():
	get_tree().quit()

func _on_main_menu_pressed():
	$CanvasLayer/MainMenu/Confirmation.visible = true

func _on_no_pressed():
	$CanvasLayer/MainMenu/Confirmation.visible = false

func _on_yes_pressed():
	_restart()

func _on_deck_creation_pressed():
	get_tree().change_scene_to_file("res://Scenes/deck_creation.tscn")

#region Setup

func _attempt_download_zip():
	$CanvasLayer/Popup/ProgressBar.max_value = 60000000 #Yeah I'm just hard-coding that it expects ~60 MB cuz getting the actual number is tricky
	$CanvasLayer/Failure.visible = false
	$CanvasLayer/Popup.visible = true
	$CanvasLayer/Popup/Label.text = tr("DOWNLOAD_CARDS")
	$HTTPManager.job(proper_hypertext + Server.websocketURL + "/cardData.zip").on_failure(_download_zip_failed).on_success(_download_zip_suceeded).download("user://temp_cardData.zip")

func _download_zip_suceeded(_result=null):
	DirAccess.rename_absolute("user://temp_cardData.zip", "user://cardData.zip")
	_attempt_load_zip()

func _attempt_load_zip():
	$CanvasLayer/Failure.visible = false
	$CanvasLayer/Popup.visible = true
	$CanvasLayer/Popup/Label.text = tr("DOWNLOAD_CARDS")
	var success = ProjectSettings.load_resource_pack("user://cardData.zip")
	if success:
		_start_data()
	else:
		_load_zip_failed()

func _attempt_download_version():
	pass

func _start_data():
	Settings.card_version = FileAccess.get_file_as_string("res://cardLocalization/card_version.txt")
	%CardVersionText.text += Settings.card_version
	json.parse(FileAccess.get_file_as_string("res://cardData.json"))
	Database.setup_data(json.data, Settings._connect_local.bind($Timer2.start))
	#go should include download version data
		#    if succeed set info
		#    if fail raise alert

func _do_final():
	Database.setup = true
	$CanvasLayer/Popup.visible = false

func _download_zip_failed(_result):
	DirAccess.remove_absolute("user://temp_cardData.zip")
	$CanvasLayer/Failure/Title.text = tr("DOWNLOAD_FAIL")
	$CanvasLayer/Failure/Body.text = tr("DOWNLOAD_FAIL_FULL")
	$CanvasLayer/Failure/TryAgain_Download.visible = true
	$CanvasLayer/Failure/TryAgain_Import.visible = false
	
	$CanvasLayer/Failure.visible = true

func _load_zip_failed():
	$CanvasLayer/Failure/Title.text = tr("LOAD_FAIL")
	$CanvasLayer/Failure/Body.text = tr("LOAD_FAIL_FULL")
	$CanvasLayer/Failure/TryAgain_Download.visible = false
	$CanvasLayer/Failure/TryAgain_Import.visible = true
	
	$CanvasLayer/Failure.visible = true

func _download_version_failed(_result):
	pass

func _download_progress(_assigned_files, _current_files, total_bytes, current_bytes):
	$CanvasLayer/Popup/ProgressBar.value = current_bytes

#endregion

#region Settings
@onready var menus = {
	"option": %OptionPanel,
	"credits": %CreditsPanel,
	"create_lobby": %LobbyCreateMenu,
	"join_lobby": %LobbyPanel,
	"spectate_game": %SpectatePanel,
	"customization": %CustomizationPanel
}

## Ensures popup menus are mutually exclusive so only one can appear at once
func switch_menu(m: String):
	# If the menu is already visible, toggle it off and exit early
	if menus[m].visible:
		menus[m].visible = false
		return
	for menu in menus:
		menus[menu].visible = (menu == m)

func _on_options_pressed():
	switch_menu("option")
	print($WebSocket.socket.get_close_code())

func _on_check_unrevealed_pressed():
	Settings.update_settings("AllowUnrevealed",%CheckUnrevealed.button_pressed)

func _on_allow_proxies_pressed():
	Settings.update_settings("AllowProxies",%AllowProxies.button_pressed)

func _on_use_card_language_pressed() -> void:
	Settings.update_settings("UseCardLanguage",%UseCardLanguage.button_pressed)
	%AllowProxies.disabled = !Settings.settings.UseCardLanguage
	%AllowProxies.modulate.a = 0.5 if !Settings.settings.UseCardLanguage else 1

func _on_en_only_pressed() -> void:
	Settings.update_settings("OnlyEN", %OnlyEN.button_pressed)
	send_command("Server","Update Numbers")

func _on_language_selected(index_selected):
	Settings.update_settings("Language",Settings.languages[index_selected][0])
	%LanguageSelect.text = Settings.languages[index_selected][1]
	%InfoPanel.update_word_wrap()
	match Settings.settings.Language:
		"en", "es", "fr", "ko", "vi":
			chat.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		"ja":
			chat.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	fix_font_size()
	_restart()

func _on_sfx_slider_drag_ended(value_changed=null):
	%SFXTestAudio.play()

func _on_sfx_slider_value_changed(value):
	AudioServer.set_bus_volume_db(Settings.sfx_bus_index, value)
	Settings.update_settings("SFXVolume", value)
	if value <= -29:
		AudioServer.set_bus_mute(Settings.sfx_bus_index, true)
	else:
		AudioServer.set_bus_mute(Settings.sfx_bus_index, false)

func _on_bgm_slider_value_changed(value):
	AudioServer.set_bus_volume_db(Settings.bgm_bus_index, value)
	Settings.update_settings("BGMVolume", value)
	if value < -39:
		AudioServer.set_bus_mute(Settings.bgm_bus_index, true)
	else:
		AudioServer.set_bus_mute(Settings.bgm_bus_index, false)

func _on_playmat_dice_custom_pressed():
	switch_menu("customization")

func _on_cosmetics_exit_pressed():
	%CustomizationPanel.visible = false

func _on_playmat_pressed():
	%PlaymatLoadDialog.visible = true

func _on_dice_pressed():
	%DiceLoadDialog.visible = true

func _on_playmat_load_dialog_file_selected(path):
	playmat = Image.load_from_file(path)
	playmat.resize(3485,1480)
	%PlaymatTextureRect.texture = ImageTexture.create_from_image(playmat)
	Settings.update_settings("Playmat",Array(playmat.save_webp_to_buffer(true)))

func _on_dice_load_dialog_file_selected(path):
	dice = Image.load_from_file(path)
	%Die.new_texture(dice)
	Settings.update_settings("Dice",Array(dice.save_webp_to_buffer(true)))

func _on_playmat_default_pressed():
	playmat = null
	%PlaymatTextureRect.texture = default_playmat
	Settings.update_settings("Playmat",null)

func _on_dice_default_pressed():
	dice = null
	%Die.new_texture(default_dice)
	Settings.update_settings("Dice",null)

func _on_hide_cosmetics_toggled(toggled_on):
	if toggled_on:
		opponentSide._hide_cosmetics()
	else:
		opponentSide._redo_cosmetics()
#endregion

func _on_info_button_pressed():
	switch_menu("credits")

func _on_deck_location_button_pressed():
	%DeckLocation.visible = !%DeckLocation.visible

#region Sidebar
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

func _select_step(step_id):
	send_command("Game","Select Step",{"step":step_id})

func _actually_select_step(step_id):
	for stepButton in $CanvasLayer/Sidebar/Steps.get_children():
		if stepButton.name.contains(str(step_id)):
			stepButton.set_pressed_no_signal(true)
		else:
			stepButton.set_pressed_no_signal(false)
	if yourSide:
		yourSide.step = step_id

func _on_step_pressed(toggle_on, step_id):
	$CanvasLayer/Sidebar/Steps.get_node("Step" + str(step_id)).set_pressed_no_signal(!toggle_on)
	if !yourSide or !yourSide.is_turn:
		return
	_select_step(step_id)

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
					_select_step(newStep)
			elif event.is_action_pressed("Last Step"):
				var newStep = _last_step()
				_select_step(newStep)
#endregion


func fix_font_size():
	#Different languages have different text sizes. I've been managing the labels manually (bad)
	#	but buttons had too much variance for one font size to work.
	#Check fix_font_tool.gd
	
	var all_labels = []
	findByClass(self, "Button", all_labels)
	for label in all_labels:
		if label.auto_translate:
			if !label.has_meta("fontSize"):
				label.set_meta("fontSize", label.get_theme_font_size("font_size"))
			#Scale is 0.8 here but 0.9 in the deck builder. This is intentional, and returns the best results
			FixFontTool.apply_text_with_corrected_max_scale(label.size, label, tr(label.text), 0.8, false, Vector2(), label.get_meta("fontSize"))

#region WebSocket

func send_command(supertype:String, command:String, data=null) -> void:
	if %LobbyCreate.disabled:
		#Really hacky way to check if the websocket is connected. I'm tired.
		return
	if !data:
		data = {}
	%WebSocket.send_dict({"supertype":supertype, "command":command, "data":data})

func _on_websocket_connected(url):
	%LobbyCreate.disabled = false
	%LobbyJoin.disabled = false
	%GameSpectate.disabled = false
	
	# NOTE: This section is for the dialog in main menu
	# solely for the purpose of query param deck check
	if OS.has_feature("web"):
		%ConfirmDialog.set_yes_button_disabled(false)

func _on_websocket_received(raw_data):
	var needed_string = raw_data.get_string_from_ascii()
	
	#When multiple commands come in at once, they're just put next to each other
	#This code splits those up into a list of sequential commands
	var commands = needed_string.split("}{")
	for index in range(commands.size()):
		var command = commands[index]
		if index>0:
			command = "{" + command
		if index < commands.size()-1:
			command += "}"
			
		json.parse(command)
		var message = json.data
		
		if "number" in message:
			var new_number = int(message["number"])
			if new_number == packet_number:
				print("Repeated Packet")
			elif new_number > packet_number + 1:
				print("Skipped Packet")
			elif new_number < packet_number:
				print("Received Packet Out Of Order")
			packet_number = new_number
		
		if "supertype" in message and "command" in message:
			var data = message["data"] if "data" in message else {}
			match message["supertype"]:
				"Server":
					match message["command"]:
						"Created Lobby":
							show_lobby(data["host_name"],data["id"],true,{},null,false,false,false)
						"Found Lobbies":
							if "lobbies" in data:
								found_lobbies(data["lobbies"])
						"Found Games":
							if "games" in data:
								found_games(data["games"])
						"Create Lobby Failed":
							print("Failed to Create Lobby")
							hide_lobby_options()
							%LobbyButtons.visible = true
						"Join Lobby Failed":
							print("Failed to Join Lobby")
							lobby_list.visible = false
						"Spectate Game Failed":
							print("Failed to Spectate Game")
							game_list.visible = false
						"Player Info":
							if "id" in data and "name" in data:
								player_id = data["id"]
								player_name = data["name"]
								if Settings.settings["Name"] != "":
									player_name = Settings.settings["Name"]
									update_name(player_name)
								%PlayerName.placeholder_text = player_name
							if "current" in data and "en_current" in data and "unreleased" in data:
								for number in data["current"]:
									Database.current_banlist[number] = int(data["current"][number])
									Database.unreleased[number] = int(data["current"][number])
								for number in data["en_current"]:
									Database.en_current_banlist[number] = int(data["en_current"][number])
								for number in data["unreleased"]:
									var numbers_found = [number]
									for i in range(number.length()):
										if number[i] == "*":
											var new_numbers_found = []
											for num in range(10):
												for old_number in numbers_found:
													var temp_number = old_number.left(i) + str(num) + old_number.right(number.length()-i-1)
													new_numbers_found.append(temp_number)
											numbers_found = new_numbers_found.duplicate()
									for found in numbers_found:
										Database.unreleased[found] = int(data["unreleased"][number])
							if "server_id" in data:
								%ServerCode.text = data["server_id"]
						"Numbers":
							if "players" in data and "lobbies" in data and "en_lobbies" in data and "games" in data and "en_games" in data and !inGame:
								player_count.text = tr("PLAYERS_ONLINE").format({"amount":int(data["players"])})
								lobby_join_button.text = tr("LOBBY_JOIN") + " ({amount})".format({"amount":int(data["en_lobbies"] if Settings.settings.OnlyEN else data["lobbies"])})
								spectate_button.text = tr("LOBBY_SPECTATE") + " ({amount})".format({"amount":int(data["en_games"] if Settings.settings.OnlyEN else data["games"])})
						"Error":
							if "error_text" in data:
								$CanvasLayer/Error/RichTextLabel.text = data["error_text"]
								$CanvasLayer/Error.visible = true
						"Spectate":
							if "game_state" in data:
								_enable_steps(!data["game_state"]["firstTurn"])
								_actually_select_step(int(data["game_state"]["step"]))
								show_spectated_game(data["game_state"]["players"])
						_:
							pass
				"Lobby":
					lobby_command(message["command"], data)
				"Game":
					game_command(message["command"], data)
				"Your Side":
					if yourSide:
						yourSide.side_command(message["command"], data)
				"Opponent Side":
					if opponentSide:
						opponentSide.opponent_side_command(message["command"], data)
				"Spectate Side":
					if "player" in data and data["player"] in spectatedSides:
						spectatedSides[data["player"]].opponent_side_command(message["command"],data)
				_:
					pass

#endregion

#region Lobbies

func lobby_command(command:String, data:Dictionary):
	match command:
		"Update":
			if "state" in data:
				var state = data["state"]
				update_lobby(data["lobby_id"],state["waiting"],state["chosen"],data["you_are_chosen"],state["host_ready"],state["chosen_ready"],data["reason"])
		"Join":
			if "id" in data and "hostName" in data:
				show_lobby(data["hostName"],data["id"],false,{},null,false,false,false)
		"Close":
			clear_lobby_menu()
			%DeckList.visible = false
			%LobbyPanel.visible = false
			%LobbyButtons.visible = !inGame
		"Deck Legality":
			if "legal" in data and "reasons" in data:
				if data["legal"]:
					if lobby_you_are_host:
						lobby_host_ready.visible = false
					else:
						lobby_chosen_ready.visible = false
				else:
					if lobby_you_are_host:
						lobby_host_deck_select.disabled = false
						lobby_host_ready.disabled = false
						lobby_host_ready.text = tr("LOBBY_READY")
					else:
						lobby_chosen_deck_select.disabled = false
						lobby_chosen_ready.disabled = false
						lobby_chosen_ready.text = tr("LOBBY_READY")
					for reason in data["reasons"]:
						lobby_deckerrorlist.text += tr(reason[0]).format({"cardNum":reason[1]}) + "\n"
					lobby_deckerror.visible = true
		"Game Start":
			if "id" in data and "opponent_id" in data and "name" in data and !inGame:
				show_game(data["id"],data["opponent_id"],data["name"])
		"Game Start Without You":
			if "id" in data and !gameToSpectate:
				%SpectateConfirmPanel.visible = true
				%RPSWaitLabel.text = tr("LOBBY_GAMESTART_SPECTATE")
				gameToSpectate = data["id"]
		_:
			pass

func update_name(new_name:String):
	Settings.update_settings("Name",new_name)
	if new_name == "":
		new_name = %PlayerName.placeholder_text
	send_command("Server","Name Change",{"new_name":new_name})

func create_lobby_options() -> void:
	switch_menu("create_lobby")
	lobby_banlist.selected = 2 if Settings.settings.OnlyEN else 1
	

func hide_lobby_options() -> void:
	%LobbyCreateMenu.visible = false

func create_lobby() -> void:
	%LobbyCreateMenu.visible = false
	var settings = {}
	if lobby_private.button_pressed:
		settings["public"] = false
	if lobby_spectators.button_pressed:
		settings["spectators"] = true
	if Settings.settings.OnlyEN:
		settings["onlyEN"] = true
	if lobby_banlist.selected == 1:
		settings["banlist"] = Database.current_banlist
	elif lobby_banlist.selected == 2:
		settings["banlist"] = Database.en_current_banlist
	elif lobby_banlist.selected == 3:
		settings["banlist"] = Database.unreleased
	else:
		settings["banlist"] = {}
	send_command("Server","Create Lobby",{"settings":settings})

func find_lobbies() -> void:
	#Should be updated to allow filtering
	send_command("Server","Find Lobbies")
	
	switch_menu("join_lobby")
	lobby_list_searching_text.visible = true
	lobby_list_code.text = ""
	lobby_list_code_button.disabled = true
	for lobby_info in lobby_list_found.get_children():
		if lobby_info.get_class() == "Button":
			lobby_info.queue_free()

func found_lobbies(found:Array) -> void:
	for lobby_info in found:
		if bool(lobby_info["only_en"]) or !Settings.settings.OnlyEN:
			var lobbyButton = Button.new()
			lobbyButton.auto_translate = false
			lobbyButton.text = lobby_info["hostName"] + " (%d waiting)" % lobby_info["waiting"] + "\n" + tr("LOBBY_BANLIST") + ": "
			match int(lobby_info["banlist"]):
				0:
					lobbyButton.text += tr("LOBBY_BANLIST_NONE")
				1:
					lobbyButton.text += tr("LOBBY_BANLIST_CURRENT")
				2:
					lobbyButton.text += tr("LOBBY_BANLIST_CURRENT_EN")
				3:
					lobbyButton.text += tr("LOBBY_BANLIST_UNRELEASED")
				_:
					lobbyButton.text += tr("LOBBY_BANLIST_CUSTOM")
			if bool(lobby_info["only_en"]) and !Settings.settings.OnlyEN:
				lobbyButton.text += "\n" + tr("OPTION_EN")
			lobbyButton.pressed.connect(join_lobby.bind(lobby_info["id"]))
			lobbyButton.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			lobbyButton.add_theme_font_size_override("font_size", 25)
			lobby_list_found.add_child(lobbyButton)
	%LobbiesFoundLabel.text = tr("LOBBY_PUBLIC_LOBBIES_FOUND").format({"amount": str(found.size())})
	lobby_list_searching_text.visible = false

func close_lobby_list() -> void:
	lobby_list.visible = false

func join_lobby(lobby_id:String) -> void:
	send_command("Server","Join Lobby",{"lobby":lobby_id})
	lobby_list_code.text = ""

func join_lobby_from_code() -> void:
	if lobby_list_code.text != "":
		join_lobby(lobby_list_code.text)

func update_join_from_code_button(current_string:String) -> void:
	lobby_list_code_button.disabled = (current_string == "")

func find_games() -> void:
	#Should be updated to allow filtering
	send_command("Server","Find Games")
	
	switch_menu("spectate_game")
	game_list_searching_text.visible = true
	game_list_code.text = ""
	game_list_code_button.disabled = true
	for game_info in game_list_found.get_children():
		if game_info.get_class() == "Button":
			game_info.queue_free()

func found_games(found:Array) -> void:
	for game_info in found:
		if bool(game_info["only_en"]) or !Settings.settings.OnlyEN:
			var gameButton = Button.new()
			gameButton.auto_translate = false
			gameButton.text = tr("GAME_VS").format({"player1":game_info["players"][0],"player2":game_info["players"][1]})
			gameButton.pressed.connect(spectate_game.bind(game_info["id"]))
			gameButton.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			gameButton.add_theme_font_size_override("font_size", 25)
			game_list_found.add_child(gameButton)
	game_list_searching_text.visible = false
	%SpectateFoundLabel.text = tr("LOBBY_PUBLIC_LOBBIES_FOUND").format({"amount": str(found.size())})

func close_game_list() -> void:
	game_list.visible = false

func spectate_game(game_id:String) -> void:
	send_command("Server","Spectate",{"game":game_id})
	game_list_code.text = ""

func spectate_game_from_code() -> void:
	if game_list_code.text != "":
		spectate_game(game_list_code.text)

func update_spectate_from_code_button(current_string:String) -> void:
	game_list_code_button.disabled = (current_string == "")

func show_lobby(host_name:String, lobby_id:String, you_are_host:bool, waiting:Dictionary, chosen, you_are_chosen:bool, host_ready:bool, chosen_ready:bool):
	if !current_lobby:
		clear_lobby_menu()
		
		lobby_host_name.text = host_name
		current_lobby = lobby_id
		if you_are_host:
			lobby_host_options.visible = true
			lobby_you_are_host = true
		
		update_lobby(lobby_id, waiting, chosen, you_are_chosen, host_ready, chosen_ready, "Initialize")
		%LobbyPanel.visible=false
		%LobbyScreen.visible=true

func update_lobby(lobby_id:String, waiting:Dictionary, chosen, you_are_chosen:bool, host_ready:bool, chosen_ready:bool, reason:String):
	if current_lobby == lobby_id:
		if !you_are_chosen:
			lobby_chosen_options.visible = false
		if !chosen:
			lobby_chosen_name.text = tr("LOBBY_NONE_CHOSEN")
		
		for waitButton in lobby_waiting.get_children():
			if waitButton.get_class() == "Button":
				waitButton.queue_free()
		
		for wait_id in waiting:
			if wait_id == chosen:
				lobby_chosen_name.text = waiting[chosen]
				if you_are_chosen:
					lobby_chosen_options.visible = true
			else:
				var waitButton = Button.new()
				waitButton.auto_translate = false
				waitButton.text = waiting[wait_id]
				if lobby_you_are_host:
					waitButton.pressed.connect(choose_opponent.bind(wait_id))
				else:
					waitButton.disabled = true
				waitButton.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
				waitButton.add_theme_font_size_override("font_size", 25)
				lobby_waiting.add_child(waitButton)
		
		lobby_host_ready.button_pressed = host_ready
		lobby_chosen_ready.button_pressed = chosen_ready
		lobby_host_ready_text.visible = host_ready
		lobby_chosen_ready_text.visible = chosen_ready
		
		lobby_code.text = current_lobby
		
		if lobby_you_are_host and host_ready and chosen_ready:
			lobby_game_start.visible = true

func choose_opponent(player_id):
	send_command("Lobby","Choose Opponent",{"chosen":player_id})

func _on_deck_select_pressed():
	%DeckList._all_decks()
	%DeckList.visible = true

func _hide_deck_list():
	%DeckList.visible = false

func _on_deck_list_selected(deckJSON):
	deckInfo = deckJSON
	if lobby_you_are_host:
		lobby_host_deck_select.text = deckInfo.deckName
		lobby_host_ready.disabled = false
	else:
		lobby_chosen_deck_select.text = deckInfo.deckName
		lobby_chosen_ready.disabled = false
	_hide_deck_list()

func ready_lobby():
	send_command("Lobby","Ready",{"deck":deckInfo})
	if lobby_you_are_host:
		lobby_host_deck_select.disabled = true
		#lobby_host_ready.disabled = true
		lobby_host_ready.text = tr("LOBBY_WAITING")
	else:
		lobby_chosen_deck_select.disabled = true
		#lobby_chosen_ready.disabled = true
		lobby_chosen_ready.text = tr("LOBBY_WAITING")

func close_deckerror() -> void:
	lobby_deckerror.visible = false
	lobby_deckerrorlist.text = ""

func exit_lobby():
	if current_lobby:
		if lobby_you_are_host:
			send_command("Lobby","Close Lobby")
		else:
			send_command("Lobby","Leave Lobby")
		
		clear_lobby_menu()
		lobby_host_ready.disabled = true
		lobby_chosen_ready.disabled = true
		lobby_host_ready.visible = true
		lobby_chosen_ready.visible = true
		lobby_host_ready.text = tr("LOBBY_READY")
		lobby_chosen_ready.text = tr("LOBBY_READY")
		lobby_host_deck_select.text = tr("DECK_SELECT")
		lobby_chosen_deck_select.text = tr("DECK_SELECT")
		lobby_host_deck_select.disabled = false
		lobby_chosen_deck_select.disabled = false
		deckInfo = null
		%LobbyScreen.visible = false

func clear_lobby_menu() -> void:
	for waitButton in lobby_waiting.get_children():
		if waitButton.get_class() == "Button":
			waitButton.queue_free()
	lobby_chosen_name.text = tr("LOBBY_NONE_CHOSEN")
	lobby_chosen_ready_text.visible = false
	lobby_chosen_options.visible = false
	lobby_host_name.text = tr("LOBBY_NONE_CHOSEN")
	lobby_host_ready_text.visible = false
	lobby_host_options.visible = false
	current_lobby = null
	lobby_you_are_host = false
	%LobbyButtons.visible = false

func start_game():
	send_command("Lobby","Start Game")

func show_game(game_id:String,opponent_id:String,opponent_name:String) -> void:
	inGame = true
	
	yourSide = player_side.instantiate()
	yourSide.is_your_side = true
	yourSide.name = "yourSide"
	yourSide.player_id = player_id
	yourSide.player_name = player_name
	opponentSide = player_side.instantiate()
	opponentSide.name = "opponentSide"
	opponentSide.player_id = opponent_id
	opponentSide.player_name = opponent_name
	yourSide.card_info_set.connect(update_info)
	yourSide.card_info_clear.connect(clear_info)
	opponentSide.card_info_set.connect(update_info)
	opponentSide.card_info_clear.connect(clear_info)
	call_deferred("add_child",yourSide)
	call_deferred("add_child",opponentSide)
	
	yourSide.ended_turn.connect(_on_end_turn)
	yourSide.made_turn_choice.connect(_on_choice_made)
	yourSide.rps.connect(_on_rps)
	
	$CanvasLayer/Sidebar/OptionsWindow/GameCode.text = game_id
	
	_hide_main_menu()
	
	fix_font_size()

func _hide_main_menu():
	%LobbyScreen.visible = false
	%LobbyButtons.visible = false
	%TitleVBox.visible = false
	%Exit.visible = false
	%OptionPanel.visible = false
	%OptionButton.visible = false
	%gradient.visible = false
	%SpectateConfirmPanel.visible = false
	%LobbyPanel.visible = false
	%SpectatePanel.visible = false
	%LeftBarMargins.visible = false
	%ClientVersionText.visible = false
	%CardVersionText.visible = false
	
	$CanvasLayer/Sidebar.visible = true
	$CanvasLayer/Sidebar/Tabs/Chat.visible = true

func _spectate_yes():
	%SpectateNo.disabled = true
	%SpectateYes.disabled = true
	send_command("Server","Spectate",{"game":gameToSpectate})

func _spectate_no():
	%SpectateConfirmPanel.visible = false
	gameToSpectate = null

func show_spectated_game(player_info:Dictionary) -> void:
	inGame = true
	var firstPlayer = true
	for player in player_info:
		var newSide = player_side.instantiate()
		newSide.is_front = firstPlayer
		newSide.side_info = player_info[player]["side"]
		newSide.player_id = player
		newSide.player_name = player_info[player]["name"]
		newSide.card_info_set.connect(update_info)
		newSide.card_info_clear.connect(clear_info)
		spectatedSides[player] = newSide
		firstPlayer = false
		call_deferred("add_child",newSide)
	
	_hide_main_menu()
	%MainMenu.visible = true
	$CanvasLayer/Sidebar/ChatWindow/HBoxContainer.visible = false
	
	fix_font_size()

#endregion

#region Game Logic

func game_command(command: String, data: Dictionary) -> void:
	match command:
		"RPS Restart":
			yourSide.specialRestart()
		"RPS Win":
			yourSide.rps_end()
			opponentSide.rps_end()
			yourSide._show_turn_choice()
		"RPS Loss":
			yourSide.rps_end()
			opponentSide.rps_end()
		"Set Turn 1":
			if "is_turn" in data:
				yourSide.set_is_turn(data["is_turn"])
				yourSide.set_player1(data["is_turn"])
		
		"Start Ingame RPS":
			%RPSWaitLabel.visible = false
			%RPSHBox.visible = true
			%Rock.disabled = false
			%Paper.disabled = false
			%Scissors.disabled = false
			%RPSWaitLabel.text = tr("RPS_WAIT")
			%QuestionRPS.visible = true
			rps = true
		"Ingame RPS Restart":
			%Rock.disabled = false
			%Paper.disabled = false
			%Scissors.disabled = false
		"Ingame RPS Win":
			%RPSHBox.visible = false
			%RPSWaitLabel.visible = true
			%RPSWaitLabel.text = tr("INGAME_RPS_WON")
			rps = false
			$Timer.start()
		"Ingame RPS Loss":
			%RPSHBox.visible = false
			%RPSWaitLabel.visible = true
			%RPSWaitLabel.text = tr("INGAME_RPS_LOST")
			rps = false
			$Timer.start()
		
		"Select Step":
			if "step" in data:
				_actually_select_step(int(data["step"]))
		
		"Chat":
			if "sender" in data and "message" in data:
				if data["sender"] == player_id:
					chat.text += "\n\n" + tr("YOU") + ": " + data["message"]
				else:
					var sender_name = "ERROR"
					if opponentSide:
						sender_name = opponentSide.player_name
					elif data["sender"] in spectatedSides:
						sender_name = spectatedSides[data["sender"]].player_name
					chat.text += "\n\n" + sender_name + ": " + data["message"]
					$CanvasLayer/Sidebar/Tabs/Chat/Notification.visible = !$CanvasLayer/Sidebar/ChatWindow.visible
				$CanvasLayer/Sidebar/ChatWindow/ScrollContainer.scroll_vertical = $CanvasLayer/Sidebar/ChatWindow/ScrollContainer.get_v_scroll_bar().max_value
		"Game Message":
			if "sender" in data and "message_code" in data and "untranslated" in data and "translated" in data:
				var format_info = data["untranslated"]
				for key in data["translated"]:
					#There are two places the translation could be
					#My options were to add a THIRD dictionary to the call or this
					#Tries the cardLocalization one first (that's where most are)
					#If it's unchanged it's probably not there, so it tries the regular one
					
					var new_value = Settings.trans(data["translated"][key])
					if new_value == data["translated"][key]:
						new_value = tr(data["translated"][key])
					format_info[key] = new_value
				if data["sender"] == player_id:
					chat.text += "\n" + tr("YOU_" + data["message_code"]).format(format_info)
				else:
					if opponentSide:
						format_info["person"] = opponentSide.player_name
					elif data["sender"] in spectatedSides:
						format_info["person"] = spectatedSides[data["sender"]].player_name
					chat.text += "\n" + tr(data["message_code"]).format(format_info)
				$CanvasLayer/Sidebar/ChatWindow/ScrollContainer.scroll_vertical = $CanvasLayer/Sidebar/ChatWindow/ScrollContainer.get_v_scroll_bar().max_value
		"Game Win":
			if "winner" in data and "reason" in data:
				if data["winner"] == player_id:
					%SpectateConfirmLabel.text = tr("WIN") + "\n" + tr(data["reason"]).format({"person":opponentSide.player_name})
					yourSide.can_do_things = false
					yourSide._on_cancel_pressed()
					opponentSide._on_cancel_pressed()
					%QuestionRPS.visible = false
				else:
					if opponentSide:
						%SpectateConfirmLabel.text = tr("LOSS") + "\n" + tr("YOU_" + data["reason"])
						yourSide.can_do_things = false
						yourSide._on_cancel_pressed()
						opponentSide._on_cancel_pressed()
						%QuestionRPS.visible = false
					elif data["winner"] in spectatedSides:
						var winner = spectatedSides[data["winner"]].player_name
						var loser = "LOSER"
						for spectatedPlayer in spectatedSides:
							if spectatedPlayer != data["winner"]:
								loser = spectatedSides[spectatedPlayer].player_name
						%SpectateConfirmLabel.text = tr("SPECTATE_WIN").format({"person":winner}) + "\n" + tr(data["reason"]).format({"person":loser})
				%SpectateMainMenu.visible = true
				%SpectateNo.visible = false
				%SpectateYes.visible = false
				#$CanvasLayer/Question.position = Vector2(422,194)
				%SpectateConfirmPanel.visible = true
		"Close":
			if inGame and !%SpectateConfirmPanel.visible:
				_restart()
		_:
			pass

func _on_rps(choice):
	send_command("Game","RPS",{"choice":choice})

func _rps_rock():
	%Rock.disabled = true
	%Paper.disabled = true
	%Scissors.disabled = true
	send_command("Game","Ingame RPS",{"choice":0})
func _rps_paper():
	%Rock.disabled = true
	%Paper.disabled = true
	%Scissors.disabled = true
	send_command("Game","Ingame RPS",{"choice":1})
func _rps_scissors():
	%Rock.disabled = true
	%Paper.disabled = true
	%Scissors.disabled = true
	send_command("Game","Ingame RPS",{"choice":2})
func _on_timer_timeout() -> void:
	if !rps:
		%QuestionRPS.visible = false

func _on_choice_made(choice):
	send_command("Game","Turn Choice",{"choice":choice})

func _on_end_turn():
	send_command("Game","End Turn")

func send_message(message):
	if message != "":
		send_command("Game","Chat",{"message":message})
		$CanvasLayer/Sidebar/ChatWindow/HBoxContainer/ToSend.text = ""

func send_message_on_click():
	send_message($CanvasLayer/Sidebar/ChatWindow/HBoxContainer/ToSend.text)

func _on_close_error_pressed() -> void:
	$CanvasLayer/Error.visible = false
	if !inGame:
		%LobbyButtons.visible = true

#endregion

func _not_real():
	#This is all for POT generation
	tr("MESSAGE_MULLIGAN")
	tr("MESSAGE_DRAW")
	tr("MESSAGE_DRAWX")
	tr("MESSAGE_MILL")
	tr("MESSAGE_MILLX")
	tr("MESSAGE_BLOOM")
	tr("MESSAGE_STAGE_ARCHIVE")
	tr("MESSAGE_STAGE_HAND")
	tr("MESSAGE_STAGE_CENTER")
	tr("MESSAGE_STAGE_COLLAB")
	tr("MESSAGE_STAGE_MOVECOLLAB")
	tr("MESSAGE_STAGE_UNBLOOM")
	tr("MESSAGE_REVEALED_HAND")
	tr("MESSAGE_REVEALED_TOPDECK")
	tr("MESSAGE_REVEALED_BOTTOMDECK")
	tr("MESSAGE_REVEALED_ARCHIVE")
	tr("MESSAGE_REVEALED_HOLOPOWER")
	tr("MESSAGE_REVEALED_BOTTOMHOLOPOWER")
	tr("MESSAGE_OSHISKILL_SP")
	tr("MESSAGE_OSHISKILL")
	tr("MESSAGE_HAND_TOPDECK")
	tr("MESSAGE_HAND_BOTTOMDECK")
	tr("MESSAGE_HAND_ARCHIVE")
	tr("MESSAGE_HAND_HOLOPOWER")
	tr("MESSAGE_HAND_REVEAL")
	tr("MESSAGE_HAND_SUPPORT_PLAY")
	tr("MESSAGE_FUDA_REVEAL")
	tr("MESSAGE_HOLOPOWER_REVEAL")
	tr("MESSAGE_DECK_MULLIGAN")
	tr("MESSAGE_DECK_UNDOMULLIGAN")
	tr("MESSAGE_DECK_SEARCH")
	tr("MESSAGE_DECK_SHUFFLE")
	tr("MESSAGE_CHEERDECK_SEARCH")
	tr("MESSAGE_CHEERDECK_SHUFFLE")
	tr("MESSAGE_HOLOPOWER_SEARCH")
	tr("MESSAGE_HOLOPOWER_SHUFFLE")
	tr("MESSAGE_FUDA_LIFE")
	tr("MESSAGE_ATTACHED_LIFE")
	tr("MESSAGE_ARCHIVE_HAND")
	tr("MESSAGE_FUDA_HAND")
	tr("MESSAGE_HOLOPOWER_HAND")
	tr("MESSAGE_ATTACHED_HAND")
	tr("MESSAGE_ARCHIVE_TOPDECK")
	tr("MESSAGE_DECK_TOPDECK")
	tr("MESSAGE_FUDA_TOPDECK")
	tr("MESSAGE_HOLOPOWER_TOPDECK")
	tr("MESSAGE_ATTACHED_TOPDECK")
	tr("MESSAGE_ARCHIVE_BOTTOMDECK")
	tr("MESSAGE_DECK_BOTTOMDECK")
	tr("MESSAGE_FUDA_BOTTOMDECK")
	tr("MESSAGE_HOLOPOWER_BOTTOMDECK")
	tr("MESSAGE_ATTACHED_BOTTOMDECK")
	tr("MESSAGE_ARCHIVE_TOPCHEERDECK")
	tr("MESSAGE_CHEERDECK_TOPCHEERDECK")
	tr("MESSAGE_FUDA_TOPCHEERDECK")
	tr("MESSAGE_ATTACHED_TOPCHEERDECK")
	tr("MESSAGE_ARCHIVE_BOTTOMCHEERDECK")
	tr("MESSAGE_CHEERDECK_BOTTOMCHEERDECK")
	tr("MESSAGE_FUDA_BOTTOMCHEERDECK")
	tr("MESSAGE_ATTACHED_BOTTOMCHEERDECK")
	tr("MESSAGE_FUDA_ARCHIVE")
	tr("MESSAGE_HOLOPOWER_ARCHIVE")
	tr("MESSAGE_ATTACHED_ARCHIVE")
	tr("MESSAGE_ARCHIVE_HOLOPOWER")
	tr("MESSAGE_FUDA_HOLOPOWER")
	tr("MESSAGE_ATTACHED_HOLOPOWER")
	tr("MESSAGE_ARTS_DAMAGE")
	tr("MESSAGE_DECK_LOOKATX")
	tr("MESSAGE_CHEERDECK_LOOKATX")
	tr("MESSAGE_CARD_BACK")
	tr("MESSAGE_CARD_BATONPASS")
	tr("MESSAGE_CARD_SWITCH")
	tr("MESSAGE_SUPPORT_ATTACH")
	tr("MESSAGE_CHEER_ATTACH")
	tr("MESSAGE_HOLOMEM_PLAY")
	tr("MESSAGE_DECK_HOLOMEM_PLAY")
	tr("MESSAGE_CHEERDECK_CHEER_ATTACH")
	tr("MESSAGE_ARCHIVE_HAND_ALL")
	tr("MESSAGE_ARCHIVE_HOLOMEM_PLAY")
	tr("MESSAGE_ARCHIVE_CHEER_ATTACH")
	tr("MESSAGE_ATTACHED_CHEER_ATTACH")
	tr("MESSAGE_ENDTURN")
	tr("MESSAGE_DIERESULT")
	tr("MESSAGE_RPS")
	tr("YOU_MESSAGE_MULLIGAN")
	tr("YOU_MESSAGE_DRAW")
	tr("YOU_MESSAGE_DRAWX")
	tr("YOU_MESSAGE_MILL")
	tr("YOU_MESSAGE_MILLX")
	tr("YOU_MESSAGE_BLOOM")
	tr("YOU_MESSAGE_STAGE_ARCHIVE")
	tr("YOU_MESSAGE_STAGE_HAND")
	tr("YOU_MESSAGE_STAGE_CENTER")
	tr("YOU_MESSAGE_STAGE_COLLAB")
	tr("YOU_MESSAGE_STAGE_MOVECOLLAB")
	tr("YOU_MESSAGE_STAGE_UNBLOOM")
	tr("YOU_MESSAGE_REVEALED_HAND")
	tr("YOU_MESSAGE_REVEALED_TOPDECK")
	tr("YOU_MESSAGE_REVEALED_BOTTOMDECK")
	tr("YOU_MESSAGE_REVEALED_ARCHIVE")
	tr("YOU_MESSAGE_REVEALED_HOLOPOWER")
	tr("YOU_MESSAGE_REVEALED_BOTTOMHOLOPOWER")
	tr("YOU_MESSAGE_OSHISKILL_SP")
	tr("YOU_MESSAGE_OSHISKILL")
	tr("YOU_MESSAGE_HAND_TOPDECK")
	tr("YOU_MESSAGE_HAND_BOTTOMDECK")
	tr("YOU_MESSAGE_HAND_ARCHIVE")
	tr("YOU_MESSAGE_HAND_HOLOPOWER")
	tr("YOU_MESSAGE_HAND_REVEAL")
	tr("YOU_MESSAGE_HAND_SUPPORT_PLAY")
	tr("YOU_MESSAGE_FUDA_REVEAL")
	tr("YOU_MESSAGE_HOLOPOWER_REVEAL")
	tr("YOU_MESSAGE_DECK_MULLIGAN")
	tr("YOU_MESSAGE_DECK_UNDOMULLIGAN")
	tr("YOU_MESSAGE_DECK_SEARCH")
	tr("YOU_MESSAGE_DECK_SHUFFLE")
	tr("YOU_MESSAGE_CHEERDECK_SEARCH")
	tr("YOU_MESSAGE_CHEERDECK_SHUFFLE")
	tr("YOU_MESSAGE_HOLOPOWER_SEARCH")
	tr("YOU_MESSAGE_HOLOPOWER_SHUFFLE")
	tr("YOU_MESSAGE_FUDA_LIFE")
	tr("YOU_MESSAGE_ATTACHED_LIFE")
	tr("YOU_MESSAGE_ARCHIVE_HAND")
	tr("YOU_MESSAGE_FUDA_HAND")
	tr("YOU_MESSAGE_HOLOPOWER_HAND")
	tr("YOU_MESSAGE_ATTACHED_HAND")
	tr("YOU_MESSAGE_ARCHIVE_TOPDECK")
	tr("YOU_MESSAGE_DECK_TOPDECK")
	tr("YOU_MESSAGE_FUDA_TOPDECK")
	tr("YOU_MESSAGE_HOLOPOWER_TOPDECK")
	tr("YOU_MESSAGE_ATTACHED_TOPDECK")
	tr("YOU_MESSAGE_ARCHIVE_BOTTOMDECK")
	tr("YOU_MESSAGE_DECK_BOTTOMDECK")
	tr("YOU_MESSAGE_FUDA_BOTTOMDECK")
	tr("YOU_MESSAGE_HOLOPOWER_BOTTOMDECK")
	tr("YOU_MESSAGE_ATTACHED_BOTTOMDECK")
	tr("YOU_MESSAGE_ARCHIVE_TOPCHEERDECK")
	tr("YOU_MESSAGE_CHEERDECK_TOPCHEERDECK")
	tr("YOU_MESSAGE_FUDA_TOPCHEERDECK")
	tr("YOU_MESSAGE_ATTACHED_TOPCHEERDECK")
	tr("YOU_MESSAGE_ARCHIVE_BOTTOMCHEERDECK")
	tr("YOU_MESSAGE_CHEERDECK_BOTTOMCHEERDECK")
	tr("YOU_MESSAGE_FUDA_BOTTOMCHEERDECK")
	tr("YOU_MESSAGE_ATTACHED_BOTTOMCHEERDECK")
	tr("YOU_MESSAGE_FUDA_ARCHIVE")
	tr("YOU_MESSAGE_HOLOPOWER_ARCHIVE")
	tr("YOU_MESSAGE_ATTACHED_ARCHIVE")
	tr("YOU_MESSAGE_ARCHIVE_HOLOPOWER")
	tr("YOU_MESSAGE_FUDA_HOLOPOWER")
	tr("YOU_MESSAGE_ATTACHED_HOLOPOWER")
	tr("YOU_MESSAGE_ARTS_DAMAGE")
	tr("YOU_MESSAGE_DECK_LOOKATX")
	tr("YOU_MESSAGE_CHEERDECK_LOOKATX")
	tr("YOU_MESSAGE_CARD_BACK")
	tr("YOU_MESSAGE_CARD_BATONPASS")
	tr("YOU_MESSAGE_CARD_SWITCH")
	tr("YOU_MESSAGE_SUPPORT_ATTACH")
	tr("YOU_MESSAGE_CHEER_ATTACH")
	tr("YOU_MESSAGE_HOLOMEM_PLAY")
	tr("YOU_MESSAGE_DECK_HOLOMEM_PLAY")
	tr("YOU_MESSAGE_CHEERDECK_CHEER_ATTACH")
	tr("YOU_MESSAGE_ARCHIVE_HAND_ALL")
	tr("YOU_MESSAGE_ARCHIVE_HOLOMEM_PLAY")
	tr("YOU_MESSAGE_ARCHIVE_CHEER_ATTACH")
	tr("YOU_MESSAGE_ATTACHED_CHEER_ATTACH")
	tr("YOU_MESSAGE_ENDTURN")
	tr("YOU_MESSAGE_DIERESULT")
	tr("YOU_MESSAGE_RPS")
	
	tr("LOSS")
	tr("WIN")
	tr("SPECTATE_WIN")
	tr("FORFEIT")
	tr("WINCONSENT_FORFEIT")
	tr("WINCONSENT_DECKOUT")
	tr("WINCONSENT_LIFE")
	tr("WINCONSENT_EMPTYSTAGE")
	tr("WINREASON_MULLIGAN")
	tr("WINREASON_DECKOUT")
	tr("WINREASON_LIFE")
	tr("WINREASON_EMPTYSTAGE")
	tr("WINREASON_FORFEIT")
	tr("YOU_WINREASON_MULLIGAN")
	tr("YOU_WINREASON_DECKOUT")
	tr("YOU_WINREASON_LIFE")
	tr("YOU_WINREASON_EMPTYSTAGE")
	tr("YOU_WINREASON_FORFEIT")
	
	tr("INGAME_RPS_WON")
	tr("INGAME_RPS_LOST")
	
	tr("LOBBY_BANLIST")
	tr("LOBBY_BANLIST_NONE")
	tr("LOBBY_BANLIST_CURRENT")
	tr("LOBBY_BANLIST_UNRELEASED")
	tr("LOBBY_BANLIST_CUSTOM")
	tr("LOBBY_PUBLIC")
	tr("LOBBY_PRIVATE")
	tr("LOBBY_SPECTATE")
	tr("LOBBY_LOBBYCODE")
	tr("LOBBY_GAMECODE")
	tr("LOBBY_ALLOWSPECTATORS")
	tr("GAME_VS")
