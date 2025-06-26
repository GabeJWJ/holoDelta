from globals.live_data import get_all_players, get_player, get_all_lobbies, get_all_games
from classes.lobby import Lobby
from utils.game_network_utils import update_numbers_all



async def call_command(player_id,command, data):
    players = get_all_players()
    lobbies = get_all_lobbies()
    games = get_all_games()
    player = get_player(player_id)
    match command:
        case "Create Lobby": 
            if player.lobby is None and player.game is None:
                settings = data["settings"] if "settings" in data else {}
                lobby = Lobby(player, settings)
                await player.tell("Server","Created Lobby",{"id":lobby.id,"host_name":lobby.host.name})
                await update_numbers_all()
            else:
                await player.tell("Server","Create Lobby Failed")
        case "Join Lobby":
            if "lobby" in data and data["lobby"] in lobbies and player.lobby is None and player.game is None:
                await lobbies[data["lobby"]].add_player(player_id)
            else:
                await player.tell("Server","Join Lobby Failed")
        case "Find Lobbies":
            #This will have to update to take filtering into account

            found = [{"id":lob.id, "hostName": lob.host.name, "waiting": len(lob.waiting), "banlist":int(lob.banlistCode)} for lob in lobbies.values() if lob.public]

            await player.tell("Server","Found Lobbies",{"lobbies":found})
        case "Find Games":
            #This will have to update to take filtering into account

            found = [{"id":game.id, "players":[p.name for p in game.players.values()] } for game in games.values() if game.allow_spectators]

            await player.tell("Server","Found Games",{"games":found})
        
        case "Spectate":
            if "game" in data and data["game"] in games and player.lobby is None and player.game is None:
                game_to_spectate = games[data["game"]]
                try:
                    game_to_spectate.spectating.append(player)
                    player.game = game_to_spectate
                    await player.tell("Server","Spectate",{"game_state":await game_to_spectate.to_dict()})
                except:
                    await player.tell("Server","Spectate Game Failed")
            else:
                await player.tell("Server","Spectate Game Failed")
        
        case "Name Change":
            if "new_name" in data and isinstance(data["new_name"],str):
                player.name = data["new_name"]

        case _:
            pass