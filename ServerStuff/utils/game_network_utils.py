from globals.live_data import get_all_players, get_all_lobbies, get_all_games

async def update_numbers_all():
    players = get_all_players()
    player_keys = list(players.keys())
    lobbies = get_all_lobbies()
    lobby_keys = list(lobbies.keys())
    games = get_all_games()
    game_keys = list(games.keys())

    for player_key in player_keys:
        if player_key in players:
            player = players[player_key]
            if player.game is None and player.lobby is None:
                await player.tell("Server", "Numbers", {"players":len(players.values())-1,"lobbies": len([lob for lob in lobbies.values() if lob.public]),"games": len([g for g in games.values() if g.allow_spectators]),"en_lobbies": len([lob for lob in lobbies.values() if lob.public and lob.only_en]),"en_games": len([g for g in games.values() if g.allow_spectators and g.only_en])})
    for game_key in game_keys:
        if game_key in games:
            game = games[game_key]
            await game.heartbeat()
    for lob_key in lobby_keys:
        if lob_key in lobbies:
            lob = lobbies[lob_key]
            await lob.heartbeat()