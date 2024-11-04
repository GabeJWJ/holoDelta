extends Node

var is_owned: bool = false
var steam_app_id: int = 480 # Test game app id
var steam_id: int = 0
var steam_username: String = ""

var lobby_id = 0
var lobby_max_members = 10

func _init():
	print("Init Steam")
	OS.set_environment("SteamAppId", str(steam_app_id))
	OS.set_environment("SteamGameId", str(steam_app_id))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	Steam.run_callbacks()

func initialize_steam():
	var initialize_response: Dictionary = Steam.steamInitEx()
	print("Did Steam Initialize?: %s " % initialize_response)
	
	if initialize_response['status'] > 0:
		return initialize_response
		#get_tree().quit()
		
	is_owned = Steam.isSubscribed()
	steam_id = Steam.getSteamID()
	steam_username = Steam.getPersonaName()

	print("steam_id %s" % steam_id)
