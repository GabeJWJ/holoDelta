extends Node

# general
var current_game_state = "running"

# top side
var top_side_hp : int = 0
var top_side_life : int = 0
var top_side_deck_count : int = 0

# bottom side
var bottom_side_hp : int = 0
var bottom_side_life : int = 0
var bottom_side_deck_count : int = 0

# recently played card
var recently_played_card: Dictionary

var time_elapsed : int

# events
var events : Array

var winner : int
var win_reason : String
