extends Node2D


@export var player_side: PackedScene
@onready var json = JSON.new()
@onready var chat = %Chat

var deckInfo

var playmat
var dice
var spMarker
var defaultSleeve
var defaultCheerSleeve
var default_playmat = preload("res://playmat.jpg")
var default_SP = preload("res://SPmarker.webp")
var default_dice = preload("res://diceTexture.png").get_image()
var playmat_file_access_web
var dice_file_access_web
var SP_file_access_web

var yourSide
var opponentSide
@export var player_id : String
@export var player_name : String

var gameToSpectate
var spectatedSides = {}

var inGame = false
var rps = false

# Lobby code only supports a-z, 0-9.
var valid_lobby_code_regex_pattern := "[^a-z0-9]"
var lobby_code_regex := RegEx.new()

#Lobby stuff
@onready var lobby_banlist = %LobbyBanlist
@onready var lobby_private = %LobbyPrivateButton
@onready var lobby_spectators = %LobbySpectatorButton
@onready var lobby_list = %LobbyPanel
@onready var lobby_list_found = %LobbiesFound
@onready var lobby_list_searching_text = %LobbyListSearchingText
@onready var lobby_list_code = %LobbyListCode
@onready var lobby_list_code_button = %JoinByCode
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
@onready var lobby_chosen_name = %JoinName
@onready var lobby_chosen_options = %JoinOptions
@onready var lobby_chosen_ready = %LobbyJoinReady
@onready var lobby_chosen_ready_text = %JoinReady
@onready var lobby_chosen_deck_select = %JoinDeckSelect
@onready var lobby_waiting = %WaitingPlayersVBox
@onready var lobby_code = %LobbyCode
@onready var copy_lobby_code_button = %CopyLobbyCodeButton
@onready var lobby_game_start = %StartGame
@onready var lobby_deckerror = %DeckErrors
@onready var lobby_deckerrorlist = %DeckErrorList
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
	proper_hypertext = "https://" if %WebSocket.use_WSS else "http://"
	%WebSocket.host = Server.websocketURL
	
	randomize()
	
	lobby_code_regex.compile(valid_lobby_code_regex_pattern)

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
	%AllowProxies.modulate.a = 0.5 if !Settings.settings.UseCardLanguage else 1.0
	%UseCardLanguage.button_pressed = Settings.settings.UseCardLanguage
	%OnlyEN.button_pressed = Settings.settings.OnlyEN
	
	%SFXSlider.value = Settings.settings.SFXVolume
	%InGameSFXSlider.value = Settings.settings.SFXVolume
	AudioServer.set_bus_volume_db(Settings.sfx_bus_index, Settings.settings.SFXVolume)
	if Settings.settings.SFXVolume <= -29:
		AudioServer.set_bus_mute(Settings.sfx_bus_index, true)
	else:
		AudioServer.set_bus_mute(Settings.sfx_bus_index, false)
	%BGMSlider.value = Settings.settings.BGMVolume
	%InGameBGMSlider.value = Settings.settings.BGMVolume
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
	if Settings.settings.has("SPMarker") and Settings.settings.SPMarker.size() > 0:
		spMarker = Image.new()
		spMarker.load_webp_from_buffer(Settings.settings.SPMarker)
		%SPPreview.texture = ImageTexture.create_from_image(spMarker)
	if OS.has_feature("web"):
		playmat_file_access_web = FileAccessWeb.new()
		playmat_file_access_web.loaded.connect(_on_playmat_web_load_dialog_file_selected)
		dice_file_access_web = FileAccessWeb.new()
		dice_file_access_web.loaded.connect(_on_dice_web_load_dialog_file_selected)
		SP_file_access_web = FileAccessWeb.new()
		SP_file_access_web.loaded.connect(_on_SP_web_load_dialog_file_selected)
	if Settings.settings.has("DefaultSleeve") and Settings.settings.DefaultSleeve.size() > 0:
		defaultSleeve = Image.new()
		defaultSleeve.load_webp_from_buffer(Settings.settings.DefaultSleeve)
		%defaultSleeve.new_sleeve(defaultSleeve, false)
	if Settings.settings.has("DefaultCheerSleeve") and Settings.settings.DefaultCheerSleeve.size() > 0:
		defaultCheerSleeve = Image.new()
		defaultCheerSleeve.load_webp_from_buffer(Settings.settings.DefaultCheerSleeve)
		%defaultCheerSleeve.new_sleeve(defaultCheerSleeve, false)
	
	%LanguageSelect.text = Settings.get_language()
	%InfoMargins.update_word_wrap()
	match Settings.settings.Language:
		"ja":
			chat.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
		_:
			chat.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
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
			#If we have the card archive we check the version and ask if they wish to update
			_attempt_download_version()
		else:
			#If not we NEED to download it - game does not work without it.
			_attempt_download_zip()
	
	#Visual
	%ClientVersionText.text += Settings.client_version
	%DeckLocation.text += ProjectSettings.globalize_path("user://Decks")
	
	%LobbiesFoundLabel.text = tr("LOBBY_PUBLIC_LOBBIES_FOUND").format({"amount": "0"})
	%SpectateFoundLabel.text = tr("SPECTATE_PUBLIC_GAMES_FOUND").format({"amount": "0"})
	
	# Connect the step buttons in the sidebar
	%Step5.button_group.pressed.connect(_on_step_pressed)
	
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
	%InfoMargins._new_info(topCard, card)

func clear_info():
	%InfoMargins._clear_showing()

func _restart(_id=null):
	if get_tree():
		get_tree().reload_current_scene()

func _on_exit_pressed():
	get_tree().quit()

func _on_main_menu_pressed():
	%MainMenuConfirm.visible = true

func _on_no_pressed():
	%MainMenuConfirm.visible = false

func _on_yes_pressed():
	_restart()

func _on_deck_creation_pressed():
	get_tree().change_scene_to_file("res://Scenes/deck_creation.tscn")

#region Setup

func _attempt_download_zip():
	%PopupProgressBar.max_value = 60000000 #Yeah I'm just hard-coding that it expects ~60 MB cuz getting the actual number is tricky
	%Failure.visible = false
	%Update.visible = false
	%Popup.visible = true
	%DownloadLabel.text = tr("DOWNLOAD_CARDS")
	
	%HTTPManager.job("https://github.com/GabeJWJ/holoDelta/releases/download/CardData/cardData.zip").on_failure(_download_zip_failed).on_success(_download_zip_suceeded).download("user://temp_cardData.zip")

func _download_zip_suceeded(_result=null):
	DirAccess.rename_absolute("user://temp_cardData.zip", "user://cardData.zip")
	DirAccess.remove_absolute("user://temp_cardData.zip")
	_attempt_load_zip()

func _attempt_load_zip():
	%Failure.visible = false
	%Update.visible = false
	%Popup.visible = true
	%DownloadLabel.text = tr("DOWNLOAD_CARDS")
	var success = ProjectSettings.load_resource_pack("user://cardData.zip")
	if success:
		_start_data()
	else:
		_load_zip_failed()

func _attempt_download_version():
	%VersionHTTPManager.job(proper_hypertext + Server.websocketURL + "/version").on_success(_download_version_succeded).on_failure(_download_version_failed).fetch()

func _download_version_succeded(result):
	if FileAccess.file_exists("user://cardData.zip"):
		var zip_reader = ZIPReader.new()
		zip_reader.open("user://cardData.zip")
		if zip_reader.file_exists("cardLocalization/card_version.txt"):
			Settings.card_version = zip_reader.read_file("cardLocalization/card_version.txt").get_string_from_ascii()
		zip_reader.close()
	
	var found_version = result.fetch()
	var update_needed = false
	if found_version.Client != Settings.client_version and not OS.has_feature("android"):
		# Android versions will not track this for now, since the export may be later/infrequent
		%UpdateClientBody.text = tr("UPDATE_MENU_CLIENT_UPDATEFOUND").format({"current":Settings.client_version, "found":found_version.Client})
		%Client_Download.disabled = false
		update_needed = true
	if found_version.Card != Settings.card_version:
		%UpdateCardBody.text = tr("UPDATE_MENU_CARD_UPDATEFOUND").format({"current":Settings.card_version, "found":found_version.Card})
		%Card_Download.disabled = false
		update_needed = true
	
	if update_needed:
		%Popup.visible = false
		switch_menu("update",false)
	else:
		_attempt_load_zip()

func _go_to_github():
	OS.shell_open("https://github.com/GabeJWJ/holoDelta/releases/latest")

func _start_data():
	Settings.card_version = FileAccess.get_file_as_string("res://cardLocalization/card_version.txt")
	%CardVersionText.text = "Card Version " + Settings.card_version
	INTJSON.parse(FileAccess.get_file_as_string("res://cardData.json"))
	Database.setup_data(INTJSON.data, Settings._connect_local.bind(%Timer2.start))

func _do_final():
	Database.setup = true
	%Popup.visible = false

func _download_zip_failed(_result):
	DirAccess.remove_absolute("user://temp_cardData.zip")
	%FailureTitle.text = tr("DOWNLOAD_FAIL")
	%FailureBody.text = tr("DOWNLOAD_FAIL_FULL")
	%TryAgain_Download.visible = true
	%TryAgain_Import.visible = false
	
	switch_menu("failure", false)

func _load_zip_failed():
	%FailureTitle.text = tr("LOAD_FAIL")
	%FailureBody.text = tr("LOAD_FAIL_FULL")
	%TryAgain_Download.visible = false
	%TryAgain_Import.visible = true
	
	switch_menu("failure", false)

func _download_version_failed(_result):
	%UpdateTitle.visible = false
	%UpdateClientBody.visible = false
	%Client_Download.visible = false
	%UpdateCardBody.visible = false
	%Card_Download.visible = false
	%UpdateNotFound.visible = true
	%Popup.visible = false
	
	switch_menu("update", false)

func _download_progress(_assigned_files, _current_files, _total_bytes, current_bytes):
	%PopupProgressBar.value = current_bytes

#endregion

#region Settings
@onready var menus = {
	"option": %OptionPanel,
	"credits": %CreditsPanel,
	"goldfish": %GoldfishStartMenu,
	"create_lobby": %LobbyCreateMenu,
	"join_lobby": %LobbyPanel,
	"spectate_game": %SpectatePanel,
	"customization": %CustomizationPanel,
	"failure": %Failure,
	"update": %Update,
	"error": %Error
}

## Ensures popup menus are mutually exclusive so only one can appear at once
func switch_menu(m: String, close_if_open = true):
	# If the menu is already visible, toggle it off and exit early
	if close_if_open:
		if menus[m].visible:
			menus[m].visible = false
			return
	for menu in menus:
		menus[menu].visible = (menu == m)

func _on_options_pressed():
	switch_menu("option")

func _on_check_unrevealed_pressed():
	Settings.update_settings("AllowUnrevealed",%CheckUnrevealed.button_pressed)

func _on_allow_proxies_pressed():
	Settings.update_settings("AllowProxies",%AllowProxies.button_pressed)

func _on_use_card_language_pressed() -> void:
	Settings.update_settings("UseCardLanguage",%UseCardLanguage.button_pressed)
	%AllowProxies.disabled = !Settings.settings.UseCardLanguage
	%AllowProxies.modulate.a = 0.5 if !Settings.settings.UseCardLanguage else 1.0

func _on_en_only_pressed() -> void:
	Settings.update_settings("OnlyEN", %OnlyEN.button_pressed)
	send_command("Server","Update Numbers")

func _on_language_selected(index_selected):
	# THIS IS REALLY BAD! DICTIONARY ORDER IS NOT RELIABLE!
	var language_code = Settings.languages.keys()[index_selected]
	Settings.update_settings("Language", language_code)
	%LanguageSelect.text = Settings.languages[language_code]
	%InfoMargins.update_word_wrap()
	match Settings.settings.Language:
		"ja":
			chat.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
		_:
			chat.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fix_font_size()
	_restart()

func _on_sfx_slider_drag_ended(_value_changed=null):
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
	if OS.has_feature("web"):
		playmat_file_access_web.open(".jpg,.png,.webp")
	else:
		%PlaymatLoadDialog.visible = true

func _on_dice_pressed():
	if OS.has_feature("web"):
		dice_file_access_web.open(".jpg,.png,.webp")
	else:
		%DiceLoadDialog.visible = true

func _on_sp_pressed() -> void:
	if OS.has_feature("web"):
		SP_file_access_web.open(".png,.webp")
	else:
		%SPLoadDialog.visible = true

func _on_playmat_load_dialog_file_selected(path):
	playmat = Image.load_from_file(path)
	playmat.resize(3485,1480)
	%PlaymatTextureRect.texture = ImageTexture.create_from_image(playmat)
	Settings.update_settings("Playmat",Array(playmat.save_webp_to_buffer(true)))

func _on_dice_load_dialog_file_selected(path):
	dice = Image.load_from_file(path)
	%Die.new_texture(dice)
	Settings.update_settings("Dice",Array(dice.save_webp_to_buffer(true)))

func _on_sp_load_dialog_file_selected(path: String) -> void:
	spMarker = Image.load_from_file(path)
	spMarker.resize(200,240)
	%SPPreview.texture = ImageTexture.create_from_image(spMarker)
	Settings.update_settings("SPMarker",Array(spMarker.save_webp_to_buffer(true)))

func _on_playmat_web_load_dialog_file_selected(_file_name: String, type: String, base64_data: String) -> void:
	var data = Marshalls.base64_to_raw(base64_data)
	playmat = Image.new()
	
	match type:
		"image/jpeg":
			playmat.load_jpg_from_buffer(data)
		"image/png":
			playmat.load_png_from_buffer(data)
		"image/webp":
			playmat.load_webp_from_buffer(data)
	
	playmat.resize(3485,1480)
	%PlaymatTextureRect.texture = ImageTexture.create_from_image(playmat)
	Settings.update_settings("Playmat",Array(playmat.save_webp_to_buffer(true)))

func _on_dice_web_load_dialog_file_selected(_file_name: String, type: String, base64_data: String) -> void:
	var data = Marshalls.base64_to_raw(base64_data)
	dice = Image.new()
	
	match type:
		"image/jpeg":
			dice.load_jpg_from_buffer(data)
		"image/png":
			dice.load_png_from_buffer(data)
		"image/webp":
			dice.load_webp_from_buffer(data)
	
	%Die.new_texture(dice)
	Settings.update_settings("Dice",Array(dice.save_webp_to_buffer(true)))

func _on_SP_web_load_dialog_file_selected(_file_name: String, type: String, base64_data: String) -> void:
	var data = Marshalls.base64_to_raw(base64_data)
	spMarker = Image.new()
	
	match type:
		"image/png":
			spMarker.load_png_from_buffer(data)
		"image/webp":
			spMarker.load_webp_from_buffer(data)
	
	spMarker.resize(200, 240)
	%SPPreview.texture = ImageTexture.create_from_image(spMarker)
	Settings.update_settings("SPMarker",Array(spMarker.save_webp_to_buffer(true)))

func _on_playmat_default_pressed():
	playmat = null
	%PlaymatTextureRect.texture = default_playmat
	Settings.update_settings("Playmat",null)

func _on_dice_default_pressed():
	dice = null
	%Die.new_texture(default_dice)
	Settings.update_settings("Dice",null)

func _on_sp_default_pressed() -> void:
	spMarker = null
	%SPPreview.texture = default_SP
	Settings.update_settings("SPMarker",null)

func _on_default_sleeve_updated(back_to_default: bool) -> void:
	if back_to_default:
		Settings.update_settings("DefaultSleeve", null)
	else:
		Settings.update_settings("DefaultSleeve", Array(%defaultSleeve.current_sleeve.save_webp_to_buffer(true)))

func _on_default_cheer_sleeve_updated(back_to_default: bool) -> void:
	if back_to_default:
		Settings.update_settings("DefaultCheerSleeve", null)
	else:
		Settings.update_settings("DefaultCheerSleeve", Array(%defaultCheerSleeve.current_sleeve.save_webp_to_buffer(true)))

func _on_hide_cosmetics_toggled(toggled_on):
	if toggled_on:
		if len(spectatedSides) > 0:
			for spectated in spectatedSides:
				spectatedSides[spectated]._hide_cosmetics()
		else:
			opponentSide._hide_cosmetics()
	else:
		if len(spectatedSides) > 0:
			for spectated in spectatedSides:
				spectatedSides[spectated]._redo_cosmetics()
		else:
			opponentSide._redo_cosmetics()
#endregion

func _on_info_button_pressed():
	switch_menu("credits")

func _on_deck_location_button_pressed():
	%DeckLocation.visible = !%DeckLocation.visible
	if %DeckLocation.visible and !(OS.has_feature("web") or OS.get_name() == "Web"):
		OS.shell_open(%DeckLocation.text)

#region Sidebar
# If you want to add more tabs to the sidebar, follow these steps:
# Create a button in the Buttons VBox and assign it the sidebar_tab button group found in the UI folder
# Add any control node as a child of SidebarHBox
# Set its horizontal alignment to fill and expand
# Add ALL content for that tab to that control node
# Assign the parent control node a unique name
# Add "unique_string": %UniqueName, to the sidebar tabs dictionary
# If you want it to cycle when user hits tab key, add it to cyclable tabs too
# Connect the button's pressed signal to a new function, and in that function call switch_sidebar_tab("unique string")
@onready var sidebar_tabs = {
	"info": %InfoMargins,
	"chat": %ChatVBoxMargins,
	"options": %OptionMargins
}

# These should be ordered correctly for the tab cycle functionality to work!
# Right now, it's currently setup to only cycle between info and chat.
@onready var cyclable_tabs = {
	# ie. first tab
	"info": %InfoMargins,
	# last tab
	"chat": %ChatVBoxMargins,
}

var current_tab = "info"
	
## Switches to the sidebar given tab. Tab names are recorded in the variable sidebar_tabs
func switch_sidebar_tab(tab):
	current_tab = tab
	for t in sidebar_tabs:
		sidebar_tabs[t].visible = (tab == t)

## Switches to either the next or previous tab
func cycle_sidebar_tab(reverse = false):
	var tabs = cyclable_tabs.keys()
	var current_idx = tabs.find(current_tab)
	var next_tab
	if reverse:
		next_tab = tabs[current_idx - 1]
	else:
		next_tab = tabs[current_idx + 1] if current_idx + 1 < tabs.size() else tabs[0]
	switch_sidebar_tab(next_tab)

## Do not call this function directly. Instead call switch_sidebar_tab("info")
func _on_card_info_pressed():
	switch_sidebar_tab("info")

## Do not call this function directly. Instead call switch_sidebar_tab("chat")
func _on_chat_pressed():
	switch_sidebar_tab("chat")
	%Notification.visible = false

## Do not call this function directly. Instead call switch_sidebar_tab("options")
func _on_sidebar_options_pressed():
	switch_sidebar_tab("options")

# The step buttons now use button groups to ensure mutual exclusivity, so much of the code here has
# been reworked. Cycling must check that a button is enabled before choosing it, and all buttons
# pressed signals connect to one function, which determines which button is currently pressed.

# New workflow:
# press a step button OR hotkey -> _select_step(id)
# Send command to server to go to selected step
# Server calls on all peers: _actually_select_step


## Sends the server command to update connected peers with the new step
func _select_step(step_id: int):
	send_command("Game","Select Step",{"step":step_id})


## Called by the server on the peer
## Iterates over all children of a node, checks if their name contains id,
## Presses them if it does, unpresses them if it doesn't (without a signal)
## Calls enable
## Finally, sets the step variable in yourSide
func _actually_select_step(step_id: int):
	for stepButton: BaseButton in get_tree().get_nodes_in_group("step_buttons"):
		if stepButton.name.contains(str(step_id)):
			stepButton.set_pressed_no_signal(true)
		else:
			# Set pressed no signal does NOT unpress other button group buttons.
			# So we still have to do it manually.
			stepButton.set_pressed_no_signal(false)
	if yourSide:
		yourSide.step = step_id

func _on_step_pressed(button: BaseButton):
	# Extremely hacky way of getting the step number
	_select_step(int(str(button.name)[4]))

## enables all steps except perf. unless allow_performance is true
func _enable_steps(allow_performance := false):
	for stepButton: BaseButton in get_tree().get_nodes_in_group("step_buttons"):
		if stepButton.name.contains("5"):
			stepButton.disabled = !allow_performance
		else:
			stepButton.disabled = false

## returns true if any of the step buttons are enabled
## this is probably to determine if control has been passed over yet
func _steps_enabled():
	for stepButton in get_tree().get_nodes_in_group("step_buttons"):
		if !stepButton.disabled:
			return true
	return false

## returns the index of the next step, taking into account perf being disabled
func _next_step():
	var result = yourSide.step + 1
	if result == 5 and %Step5.disabled:
		result = 6
	return result

## returns the index of the previous step, taking into account perf being disabled
func _last_step():
	var result = yourSide.step - 1
	if result == 0:
		result = 1
	elif result == 5 and %Step5.disabled:
		result = 4
	return result

## Handles key inputs
func _unhandled_key_input(event):
	# Refuse to handle input if your game board isn't loaded yet
	if yourSide != null:
		# Normally the tab key
		if event.is_action_pressed("SwapPanels"):
			cycle_sidebar_tab()
		# If it is your turn and at least one of your step buttons is enabled
		# This is probably to determine that the server is ready for your input?
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

func toggle_step_mouse_filters(state: bool) -> void:
	for step_button: BaseButton in get_tree().get_nodes_in_group("step_buttons"):
		if state:
			step_button.mouse_filter = Control.MOUSE_FILTER_STOP
		else:
			step_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
#endregion


func fix_font_size():
	#Different languages have different text sizes. I've been managing the labels manually (bad)
	#	but buttons had too much variance for one font size to work.
	#Check fix_font_tool.gd
	
	var all_labels = []
	findByClass(self, "Button", all_labels)
	for label: BaseButton in all_labels:
		if label.text == "":
			continue # Don't try to correct font size for labels with no text (icon only)
		if label.is_in_group("step_buttons"):
			continue # Don't mess with the font sizes on the step buttons
		if label.auto_translate:
			if !label.has_meta("fontSize"):
				label.set_meta("fontSize", label.get_theme_font_size("font_size"))
			#Scale is 0.8 here but 0.9 in the deck builder. This is intentional, and returns the best results
			FixFontTool.apply_text_with_corrected_max_scale(label.size, label, tr(label.text), 0.8, false, Vector2(), label.get_meta("fontSize"))
			pass # This is here so you can put a breakpoint to find out which label is throwing an error

#region WebSocket

func send_command(supertype:String, command:String, data=null) -> void:
	if %LobbyCreate.disabled: # This is the button to open the create lobby menu
		#Really hacky way to check if the websocket is connected. I'm tired.
		return
	if !data:
		data = {}
	%WebSocket.send_dict({"supertype":supertype, "command":command, "data":data})

func _on_websocket_connected(_url):
	%LobbyCreate.disabled = false
	%LobbyJoin.disabled = false
	%GameSpectate.disabled = false
	%Goldfish.disabled = false
	
	# NOTE: This section is for the dialog in main menu
	# solely for the purpose of query param deck check
	if OS.has_feature("web"):
		%ConfirmDialog.set_yes_button_disabled(false)

func _serf_placeholder_numbers(number):
	var numbers_found = [number]
	for i in range(number.length()):
		if number[i] == "*":
			var new_numbers_found = []
			for num in range(10):
				for old_number in numbers_found:
					var temp_number = old_number.left(i) + str(num) + old_number.right(number.length()-i-1)
					new_numbers_found.append(temp_number)
			numbers_found = new_numbers_found.duplicate()
	return numbers_found

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
			
		INTJSON.parse(command)
		var message = INTJSON.data
		
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
							if "current" in data and "en_current" in data and "unreleased" in data and "en_unreleased" in data:
								for number in data["current"]:
									Database.current_banlist[number] = int(data["current"][number])
									Database.unreleased[number] = int(data["current"][number])
								for number in data["en_current"]:
									Database.en_current_banlist[number] = int(data["en_current"][number])
									Database.en_unreleased[number] = int(data["en_current"][number])
								for number in data["unreleased"]:
									for found in _serf_placeholder_numbers(number):
										Database.unreleased[found] = int(data["unreleased"][number])
								for number in data["en_unreleased"]:
									for found in _serf_placeholder_numbers(number):
										Database.en_unreleased[found] = int(data["en_unreleased"][number])
							if "server_id" in data:
								%ServerCode.text = data["server_id"]
						"Numbers":
							if "players" in data and "lobbies" in data and "en_lobbies" in data and "games" in data and "en_games" in data and !inGame:
								player_count.text = tr("PLAYERS_ONLINE").format({"amount":int(data["players"])})
								lobby_join_button.text = tr("LOBBY_JOIN") + " ({amount})".format({"amount":int(data["en_lobbies"] if Settings.settings.OnlyEN else data["lobbies"])})
								spectate_button.text = tr("LOBBY_SPECTATE") + " ({amount})".format({"amount":int(data["en_games"] if Settings.settings.OnlyEN else data["games"])})
						"Error":
							if "error_text" in data:
								%ErrorMessage.text = "[center]" + data["error_text"] + "[/center]"
								%Error.visible = true
								%Error.get_parent().move_child(%Error, -1) # Make Error receive input events as well as being in front
						"Spectate":
							# This command is only received once when the spectator first joins
							if "game_state" in data and "game_id" in data:
								#_enable_steps(!data["game_state"]["firstTurn"])
								# I have no reliable way to reenable the perf button for spectator only
								# So I will leave it enabled from the start!
								# The best solution is the server sends whether it is turn 1 in the step command
								_enable_steps(true)
								_actually_select_step(int(data["game_state"]["step"]))
								show_spectated_game(data["game_state"]["players"], data["game_id"])
						"Goldfish":
							show_goldfish_game()
						"Goldfish Deck Legality":
							pass
						"Goldfish Failed":
							print("Failed to goldfish")
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
			exit_lobby()
			%DeckList.visible = false
			%LobbyPanel.visible = false
			%LobbyButtons.visible = !inGame
			if !inGame:
				deckInfo = null
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
			if "id" in data and "opponent_id" in data and "name" in data and "oshi" in data and "passcode" in data and !inGame:
				show_game(data["id"],data["opponent_id"],data["name"], data["oshi"], data["passcode"])
		"Game Start Without You":
			if "id" in data and !gameToSpectate:
				exit_lobby()
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
	elif lobby_banlist.selected == 4:
		settings["banlist"] = Database.en_unreleased
	else:
		settings["banlist"] = {}
	send_command("Server","Create Lobby",{"settings":settings})

func find_lobbies() -> void:
	#Should be updated to allow filtering
	send_command("Server","Find Lobbies")
	
	switch_menu("join_lobby", false)
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
				4:
					lobbyButton.text += tr("LOBBY_BANLIST_UNRELEASED_EN")
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

func _on_paste_lobby_code_button_pressed() -> void:
	var clipboard_contents: String = DisplayServer.clipboard_get()
	var filtered_text: String = lobby_code_regex.sub(clipboard_contents, "", true)

	# Lobby code is 10 characters long.
	lobby_list_code.text = filtered_text.substr(0, 10)
	update_join_from_code_button(lobby_list_code.text)

func update_join_from_code_button(current_string:String) -> void:
	lobby_list_code_button.disabled = (current_string == "")

func find_games() -> void:
	#Should be updated to allow filtering
	send_command("Server","Find Games")
	
	switch_menu("spectate_game", false)
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
	%SpectateFoundLabel.text = tr("SPECTATE_PUBLIC_GAMES_FOUND").format({"amount": str(found.size())})

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
		
		lobby_code.text = "[center]" + current_lobby + "[/center]"
		copy_lobby_code_button.disabled = false
		
		if lobby_you_are_host and host_ready and chosen_ready:
			lobby_game_start.visible = true

func _on_copy_lobby_code_button_pressed() -> void:
	DisplayServer.clipboard_set(current_lobby)

func choose_opponent(player_id):
	send_command("Lobby","Choose Opponent",{"chosen":player_id})

func _on_deck_select_pressed():
	%DeckList._all_decks()
	%DeckList.visible = true

func _hide_deck_list():
	%DeckList.visible = false

func _on_deck_list_selected(deckJSON):
	deckInfo = deckJSON
	if current_lobby:
		if lobby_you_are_host:
			lobby_host_deck_select.text = deckInfo.deckName
			lobby_host_ready.disabled = false
		else:
			lobby_chosen_deck_select.text = deckInfo.deckName
			lobby_chosen_ready.disabled = false
	else:
		%GoldfishDeck.text = deckInfo.deckName
		%FinalGoldfishCreate.disabled = false
	_hide_deck_list()

func ready_lobby():
	send_command("Lobby","Ready",{"deck":{"oshi":deckInfo.oshi, "deck": deckInfo.deck, "cheerDeck":deckInfo.cheerDeck }})
	if lobby_you_are_host:
		lobby_host_deck_select.disabled = true
		lobby_host_ready.text = tr("LOBBY_WAITING")
	else:
		lobby_chosen_deck_select.disabled = true
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
	copy_lobby_code_button.disabled = true
	lobby_you_are_host = false
	%LobbyButtons.visible = false

func start_game():
	send_command("Lobby","Start Game")

func show_game(game_id:String,opponent_id:String,opponent_name:String,opponent_oshi:Array,passcode:String) -> void:
	inGame = true
	
	if "sleeve" not in deckInfo and !%defaultSleeve.is_default:
		deckInfo["sleeve"] = %defaultSleeve.current_sleeve.save_webp_to_buffer(true)
	if "cheerSleeve" not in deckInfo and !%defaultCheerSleeve.is_default:
		deckInfo["cheerSleeve"] = %defaultCheerSleeve.current_sleeve.save_webp_to_buffer(true)
	
	yourSide = player_side.instantiate()
	yourSide.is_your_side = true
	yourSide.name = "yourSide"
	yourSide.player_id = player_id
	yourSide.player_name = player_name
	yourSide.game_id = game_id
	yourSide.download_url = proper_hypertext + Server.websocketURL
	yourSide.passcode = passcode
	opponentSide = player_side.instantiate()
	opponentSide.name = "opponentSide"
	opponentSide.player_id = opponent_id
	opponentSide.player_name = opponent_name
	opponentSide.oshi = opponent_oshi
	opponentSide.game_id = game_id
	opponentSide.download_url = proper_hypertext + Server.websocketURL
	yourSide.card_info_set.connect(update_info)
	yourSide.card_info_clear.connect(clear_info)
	opponentSide.card_info_set.connect(update_info)
	opponentSide.card_info_clear.connect(clear_info)
	call_deferred("add_child",opponentSide)
	call_deferred("add_child",yourSide)
	
	yourSide.ended_turn.connect(_on_end_turn)
	yourSide.made_turn_choice.connect(_on_choice_made)
	yourSide.rps.connect(_on_rps)
	
	%GameCode.text = "[center]" + game_id + "[/center]"
	
	_hide_main_menu()
	
	fix_font_size()

func _goldfish_menu() -> void:
	switch_menu("goldfish")

func _close_goldfish_menu() -> void:
	switch_menu("goldfish", true)

func _attempt_goldfish() -> void:
	if deckInfo:
		send_command("Server", "Start Goldfishing", {"deck_info":{"oshi":deckInfo.oshi, "deck": deckInfo.deck, "cheerDeck":deckInfo.cheerDeck }})

func show_goldfish_game() -> void:
	inGame = true
	
	if "sleeve" not in deckInfo and !%defaultSleeve.is_default:
		deckInfo["sleeve"] = %defaultSleeve.current_sleeve.save_webp_to_buffer(true)
	if "cheerSleeve" not in deckInfo and !%defaultCheerSleeve.is_default:
		deckInfo["cheerSleeve"] = %defaultCheerSleeve.current_sleeve.save_webp_to_buffer(true)
	
	yourSide = player_side.instantiate()
	yourSide.is_your_side = true
	yourSide.name = "yourSide"
	yourSide.is_goldfishing = true
	yourSide.player_id = player_id
	yourSide.player_name = player_name
	opponentSide = player_side.instantiate()
	opponentSide.name = "opponentSide"
	opponentSide.stripped_bare = true
	yourSide.card_info_set.connect(update_info)
	yourSide.card_info_clear.connect(clear_info)
	call_deferred("add_child",yourSide)
	call_deferred("add_child",opponentSide)
	
	yourSide.ended_turn.connect(_on_end_turn)
	yourSide.made_turn_choice.connect(_on_choice_made)
	
	_hide_main_menu()
	%MainMenu.visible = true
	%ChatHBox.visible = false
	
	fix_font_size()

func _hide_main_menu():
	%GoldfishStartMenu.visible = false
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
	
	# For now, this function enables the sidebar too
	%Sidebar.visible = true
	# ChatHBox gets disabled later if you are a spectator. This is here to reenable it.
	%ChatHBox.visible = true
	# Same goes for the step button mouse filters
	toggle_step_mouse_filters(true)

func _spectate_yes():
	%SpectateNo.disabled = true
	%SpectateYes.disabled = true
	send_command("Server","Spectate",{"game":gameToSpectate})

func _spectate_no():
	%SpectateConfirmPanel.visible = false
	gameToSpectate = null

func show_spectated_game(player_info:Dictionary, game_id:String) -> void:
	inGame = true
	var firstPlayer = true
	for player in player_info:
		var newSide = player_side.instantiate()
		newSide.is_front = firstPlayer
		newSide.is_spectating = true
		newSide.side_info = player_info[player]["side"]
		newSide.player_id = player
		newSide.game_id = game_id
		newSide.download_url = proper_hypertext + Server.websocketURL
		newSide.player_name = player_info[player]["name"]
		newSide.card_info_set.connect(update_info)
		newSide.card_info_clear.connect(clear_info)
		spectatedSides[player] = newSide
		firstPlayer = false
		call_deferred("add_child",newSide)
	
	# hide_main_menu shows the sidebar and chat input by default
	_hide_main_menu()
	# This is the button to return to the main menu from the spectate screen
	%MainMenu.visible = true
	# Hide the chat input and button if spectating
	%ChatHBox.visible = false
	# Disable the step button mouse filters if spectating
	toggle_step_mouse_filters(false)
	
	fix_font_size()
	
	# Trying to fix a bizarre visual bug
	var timer = Timer.new()
	add_child(timer)
	timer.start(2)
	await timer.timeout
	# For some reason, we have to hide and show
	%Buttons.visible = false
	%Buttons.visible = true

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
			%Timer.start()
		"Ingame RPS Loss":
			%RPSHBox.visible = false
			%RPSWaitLabel.visible = true
			%RPSWaitLabel.text = tr("INGAME_RPS_LOST")
			rps = false
			%Timer.start()
		
		"Select Step":
			if "step" in data:
				_actually_select_step(int(data["step"]))
		
		"Cosmetics Issues":
			print(data)
		
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
					%Notification.visible = !%ChatVBoxMargins.visible
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
		%ToSend.text = ""

func send_message_on_click():
	send_message(%ToSend.text)

func _on_close_error_pressed() -> void:
	%Error.visible = false
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
	tr("MESSAGE_DRAWBOTTOM")
	tr("MESSAGE_STAGE_BOTTOMDECK")
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
	tr("MESSAGE_HAND_REVEALALL")
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
	tr("YOU_MESSAGE_DRAWBOTTOM")
	tr("YOU_MESSAGE_STAGE_BOTTOMDECK")
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
	tr("YOU_MESSAGE_HAND_REVEALALL")
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
