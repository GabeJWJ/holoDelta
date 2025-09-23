from globals.live_data import get_all_players, get_player, get_all_lobbies, get_all_games

async def update_numbers_all():
    players = get_all_players()
    lobbies = get_all_lobbies()
    games = get_all_games()

    for player in players.values():
        if player.game is None and player.lobby is None:
            try:
                await player.tell("Server", "Numbers", {"players":len(players.values())-1,"lobbies": len([lob for lob in lobbies.values() if lob.public]),"games": len([g for g in games.values() if g.allow_spectators]),"en_lobbies": len([lob for lob in lobbies.values() if lob.public and lob.only_en]),"en_games": len([g for g in games.values() if g.allow_spectators and g.only_en])})
            except:
                # 連接已關閉，跳過此玩家
                pass
    for game in games.values():
        try:
            await game.heartbeat()
        except:
            # 遊戲可能已關閉，跳過
            pass
    for lob in lobbies.values():
        try:
            await lob.heartbeat()
        except:
            # 大廳可能已關閉，跳過
            pass