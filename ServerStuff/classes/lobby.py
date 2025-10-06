from globals.data import data
from fastapi import WebSocketDisconnect
from classes.enums import Banlist
from globals.data import get_data
from globals.live_data import get_all_lobbies, get_all_players, get_player, remove_lobby, set_lobby
from classes.game import Game
from random import sample
from utils.deck_validator import check_legal
from utils.game_network_utils import update_numbers_all

class Lobby:
    def __init__(self, host, settings = None):
        random_characters = get_data("random_characters")
        current_banlist = get_data("current_banlist")
        en_current_banlist = get_data("en_current_banlist")
        unreleased = get_data("unreleased")
        en_unreleased = get_data("en_unreleased")
        self.id = ''.join(sample(random_characters, 10))
        while self.id in get_all_lobbies():
            self.id = ''.join(sample(random_characters, 10))
        set_lobby(self.id, self)
        self.host = host
        host.lobby = self
        self.host_deck = None
        self.host_ready = False
        self.chosen = None
        self.chosen_deck = None
        self.chosen_ready = False
        self.waiting = []
        self.settings = {} if settings is None else settings
        self.only_en = self.settings["onlyEN"] if "onlyEN" in self.settings else False
        self.public = self.settings["public"] if "public" in self.settings else True
        self.banlist = self.settings["banlist"] if "banlist" in self.settings else dict(current_banlist)
        self.allow_spectators = self.settings["spectators"] if "spectators" in self.settings else False
        if self.banlist == {} and not self.only_en:
            self.banlistCode = Banlist.none
        elif self.banlist == current_banlist:
            self.banlistCode = Banlist.current
        elif self.banlist == en_current_banlist:
            self.banlistCode = Banlist.en_current
        elif self.banlist == (current_banlist | unreleased):
            self.banlistCode = Banlist.unreleased
        elif self.only_en:
            #Just realized the way I'm checking banlists is bad and awful
            #Needs a full revamp
            self.banlistCode = Banlist.en_unreleased
        else:
            self.banlistCode = Banlist.custom
        
    async def add_player(self, player_id):
        player = get_player(player_id)
        if player not in self.waiting and player != self.host:
            self.waiting.append(player)
            player.lobby = self
            await player.tell("Lobby","Join",{"id":self.id,"hostName":self.host.name})
            await self.update_all("Player Joined")
    
    async def remove_player(self, player_id):
        player = get_player(player_id)
        if player in self.waiting:
            if player in self.waiting:
                self.waiting.remove(player)
            player.lobby = None
            if self.chosen == player:
                self.chosen = None
                self.chosen_ready = False
            await player.tell("Lobby","Close")
            await self.update_all("Player Left")
        elif player == self.host:
            await self.close_lobby()
    
    async def heartbeat(self):
        try:
            await self.host.tell("Server", "Heartbeat")
        except WebSocketDisconnect:
            await self.close_lobby()

    async def close_lobby(self):
        await self.host.tell("Lobby","Close")
        for player in self.waiting:
            await player.tell("Lobby","Close")
        
        self.host.lobby = None
        for player in self.waiting:
            player.lobby = None
        self.waiting = []
        self.chosen = None
        remove_lobby(self.id)

        await update_numbers_all()
    
    async def update_all(self,reason="Update"):
        current_state = {"waiting":{player.id:player.name for player in self.waiting},"chosen":None if self.chosen is None else self.chosen.id,"host_ready":self.host_ready,"chosen_ready":self.chosen_ready}
        await self.host.tell("Lobby","Update",{"reason":reason,"state":current_state,"lobby_id":self.id,"you_are_chosen":False})
        for player in self.waiting:
            await player.tell("Lobby","Update",{"reason":reason,"state":current_state,"lobby_id":self.id,"you_are_chosen":(False if self.chosen is None else self.chosen.id == player.id)})
    
    async def call_command(self, player_id,command, data):
        players = get_all_players()
        match command:
            case "Choose Opponent":
                if "chosen" in data and data["chosen"] in players and players[data["chosen"]] in self.waiting:
                    self.chosen = get_player(data["chosen"])
                    await self.update_all("Player Chosen")
            case "Ready":
                if "deck" in data:
                    is_host = player_id == self.host.id
                    have_host_deck = self.host_deck is not None
                    is_chosen = self.chosen is not None and player_id == self.chosen.id
                    have_chosen_deck = self.chosen_deck is not None

                    if (is_host and not have_host_deck) or (is_chosen and not have_chosen_deck):
                        deck, deck_legality = check_legal(data["deck"], self.banlist, self.only_en)
                        await get_player(player_id).tell("Lobby","Deck Legality",deck_legality)

                        if deck_legality["legal"]:
                            if is_host:
                                self.host_deck = deck
                                self.host_ready = True
                                await self.update_all("Host Readied")
                            elif is_chosen:
                                self.chosen_deck = deck
                                self.chosen_ready = True
                                await self.update_all("Chosen Readied")
                    elif is_host or is_chosen:
                        await players[player_id].tell("Lobby","Deck Legality",{"legal":True,"reasons":[]})

            case "Start Game":
                if player_id == self.host.id and self.chosen is not None and self.host_deck is not None and self.chosen_deck is not None and self.host_ready and self.chosen_ready:
                    game = Game(self.host, self.host_deck, self.chosen, self.chosen_deck, self.settings)

                    await self.host.tell("Lobby","Game Start",{"id": game.id, "opponent_id":self.chosen.id, "name":self.chosen.name})
                    await self.chosen.tell("Lobby","Game Start",{"id": game.id,"opponent_id":self.host.id, "name":self.host.name})

                    if self.allow_spectators:
                        for player in self.waiting:
                            if player != self.chosen:
                                await player.tell("Lobby","Game Start Without You",{"id":game.id}) #They will be given the option to either go to main menu or spectate

                    await self.close_lobby()
            
            case "Leave Lobby":
                if players[player_id] in self.waiting:
                    await self.remove_player(player_id)
            case "Close Lobby":
                if player_id == self.host.id:
                    await self.close_lobby()

            case _:
                pass