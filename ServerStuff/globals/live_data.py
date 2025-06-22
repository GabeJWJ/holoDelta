games = {}
lobbies = {}
players = {}
manager = None

def initialize_manager(manager_instance):
    """Initialize the manager instance."""
    global manager
    manager = manager_instance

def get_manager():
    """Get the current manager instance."""
    return manager

def set_game(game_id, game_instance):
    """Set the game instance for a given game ID."""
    games[game_id] = game_instance

def remove_game(game_id):
    """Remove the game instance for a given game ID."""
    if game_id in games:
        del games[game_id]

def get_game(game_id):
    """Get the game instance for a given game ID."""
    return games.get(game_id)

def get_all_games():
    """Get all game instances."""
    return games

def set_lobby(lobby_id, lobby_instance):
    """Set the lobby instance for a given lobby ID."""
    lobbies[lobby_id] = lobby_instance

def remove_lobby(lobby_id):
    """Remove the lobby instance for a given lobby ID."""
    if lobby_id in lobbies:
        del lobbies[lobby_id]

def get_lobby(lobby_id):
    """Get the lobby instance for a given lobby ID."""
    return lobbies.get(lobby_id)

def get_all_lobbies():
    """Get all lobby instances."""
    return lobbies

def set_player(player_id, player_instance):
    """Set the player instance for a given player ID."""
    players[player_id] = player_instance

def remove_player(player_id):
    """Remove the player instance for a given player ID."""
    if player_id in players:
        del players[player_id]

def get_player(player_id):
    """Get the player instance for a given player ID."""
    return players.get(player_id)

def get_all_players():
    """Get all player instances."""
    return players