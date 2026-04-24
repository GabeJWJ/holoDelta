from globals.live_data import get_player, get_all_lobbies, get_all_games
from classes.lobby import Lobby
from classes.player import Player
from classes.game import Game
from utils.game_network_utils import update_numbers_all
from utils.deck_validator import check_legal



async def call_command(player_id,command, data):
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

            found = [{"id":lob.id, "hostName": lob.host.name, "waiting": len(lob.waiting), "banlist":int(lob.banlistCode), "only_en":lob.only_en} for lob in lobbies.values() if lob.public]

            await player.tell("Server","Found Lobbies",{"lobbies":found})
        case "Find Games":
            #This will have to update to take filtering into account

            found = [{"id":game.id, "players":[p.name for p in game.players.values()], "only_en":game.only_en } for game in games.values() if game.allow_spectators]

            await player.tell("Server","Found Games",{"games":found})
        
        case "Spectate":
            if "game" in data and data["game"] in games and player.lobby is None and player.game is None:
                game_to_spectate = games[data["game"]]
                try:
                    game_to_spectate.spectating.append(player)
                    player.game = game_to_spectate
                    await player.tell("Server","Spectate",{"game_state":await game_to_spectate.to_dict(), "game_id":game_to_spectate.id})
                except:
                    await player.tell("Server","Spectate Game Failed")
            else:
                await player.tell("Server","Spectate Game Failed")
        
        case "Get Cosmetics":
            if "game" in data and data["game"] in games and player.lobby is None and player in games[data["game"]].spectating:
                game_to_spectate = games[data["game"]]
                for game_player in game_to_spectate.cosmetics:
                        for cosmetics_type in game_to_spectate.cosmetics[game_player]:
                            if cosmetics_type != "passcode" and game_to_spectate.cosmetics[game_player][cosmetics_type]:
                                await player.tell("Spectate Side", "Cosmetics", {"player":game_player, "cosmetics_type":cosmetics_type})
        
        case "Start Goldfishing":
            if "deck_info" in data and player.lobby is None and player.game is None:
                try:
                    deck, deck_legality = check_legal(data["deck_info"], {})
                    if deck_legality["legal"]:
                        goldfish_game = Game(player, deck, Player(), {})
                        player.game = goldfish_game
                        await player.tell("Server", "Goldfish")
                    else:
                        await player.tell("Server", "Goldfish Deck Legality", deck_legality["reasons"])
                except:
                    await player.tell("Server", "Goldfish Failed")
            else:
                await player.tell("Server", "Goldfish Failed")
        
        case "Name Change":
            if "new_name" in data and isinstance(data["new_name"],str):
                player.name = data["new_name"]
        
        case "Update Numbers":
            await update_numbers_all()

        case _:
            pass