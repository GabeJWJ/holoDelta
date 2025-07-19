from globals.live_data import get_all_players, get_player, get_all_lobbies, get_all_games

async def update_numbers_all():
    players = get_all_players()
    lobbies = get_all_lobbies()
    games = get_all_games()

    for player in players.values():
        if player.game is None and player.lobby is None:
            await player.tell("Server", "Numbers", {"players":len(players.values())-1,"lobbies": len([lob for lob in lobbies.values() if lob.public]),"games": len([g for g in games.values() if g.allow_spectators]),"en_lobbies": len([lob for lob in lobbies.values() if lob.public and lob.only_en]),"en_games": len([g for g in games.values() if g.allow_spectators and g.only_en])})
    for game in games.values():
        await game.heartbeat()
    for lob in lobbies.values():
        await lob.heartbeat()