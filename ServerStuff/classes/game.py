from fastapi import WebSocketDisconnect
from globals.data import get_data
from globals.live_data import get_all_games, set_game, remove_game
from classes.side import Side
from classes.player import Player
from random import sample
from utils.game_network_utils import update_numbers_all
from utils.azure_blob_storage import delete_cosmetics

class Game:
    def __init__(self, player1: Player, player1deck: dict, player2: Player, player2deck: dict, settings : dict = None):
        random_characters = get_data("random_characters")
        self.id = ''.join(sample(random_characters, 10))
        while self.id in get_all_games():
            self.id = ''.join(sample(random_characters, 10))
        
        if player2.dummy:
            player1.goldfishing = True
            self.playing = {player1.id : Side(player1deck, self, player1, player2)}
            self.goldfish = True
        else:
            set_game(self.id, self)
            self.playing = {player1.id : Side(player1deck, self, player1, player2), player2.id : Side(player2deck, self, player2, player1)}
            self.goldfish = False
        
        self.goldfish_must_end_turn = None
        self.players = {player1.id : player1, player2.id : player2}
        player1.game = self
        player2.game = self
        self.spectating = []
        self.settings = {} if settings is None else settings
        self.only_en = self.settings["onlyEN"] if "onlyEN" in self.settings else False
        self.allow_spectators = self.settings["spectators"] if "spectators" in self.settings else False
        self.cosmetics = {player1.id: {"passcode":''.join(sample(random_characters, 10)), "sleeve":False, "cheerSleeve":False, "playmat":False, "dice":False},
                          player2.id: {"passcode":''.join(sample(random_characters, 10)), "sleeve":False, "cheerSleeve":False, "playmat":False, "dice":False}}

        self.step = 5

        #Game Start Stuff
        self.game_start = {player1.id: {"RPS":-1, "Mulligan":False, "Ready":False}, player2.id: {"RPS":-1, "Mulligan":False, "Ready":False}}
        self.current_turn = -1
        self.firstTurn = True

        #Ingame RPS
        self.in_rps = False
        self.rps = {player1.id:-1, player2.id:-1}
    
    async def close_game(self):
        for player in self.players.values():
            await player.tell("Game","Close")
            player.game = None
        
        await delete_cosmetics(self.id)

        remove_game(self.id)
        await update_numbers_all()
    
    async def _rps(self, player_id, choice):
        if player_id in self.game_start and self.game_start[player_id]["RPS"] == -1:
            self.game_start[player_id]["RPS"] = choice

            if all([start_info["RPS"]!=-1 for start_info in self.game_start.values()]):
                await self._rps_decide()

    async def _rps_decide(self):
        rps = [(player_id, self.game_start[player_id]["RPS"]) for player_id in self.game_start]

        if rps[0][1] == rps[1][1]:
            for player in self.playing:
                await self.players[player].tell("Game", "RPS Restart")

                self.game_start[player]["RPS"]=-1
        elif rps[0][1] - rps[1][1] in (-2,1):
            await self.players[rps[0][0]].tell("Game", "RPS Win")
            await self.players[rps[1][0]].tell("Game", "RPS Loss")

            self.current_turn = rps[0][0]
        else:
            await self.players[rps[1][0]].tell("Game", "RPS Win")
            await self.players[rps[0][0]].tell("Game", "RPS Loss")

            self.current_turn = rps[1][0]

    async def _on_choice_made(self, player_id, choice):
        if player_id == self.current_turn or self.goldfish:
            for player in self.players:
                if (player == player_id) ^ (not choice):
                    self.current_turn = player
                    if self.goldfish and self.players[player].dummy:
                        self.goldfish_must_end_turn = player
                    else:
                        self.playing[player].is_turn = True
                        await self.players[player].tell("Game","Set Turn 1",{"is_turn":True})
                else:
                    if not self.goldfish or not self.players[player].dummy:
                        self.playing[player].is_turn = False
                    await self.players[player].tell("Game","Set Turn 1",{"is_turn":False})

                if not self.goldfish or not self.players[player].dummy:
                    await self.playing[player].specialStart2()


    async def _mulligan(self, player_id):
        self.game_start[player_id]["Mulligan"] = True

        if self.goldfish or all([start_info["Mulligan"] for start_info in self.game_start.values()]):
            await self._all_mulligan()

    async def _all_mulligan(self):
        for side in self.playing.values():
            await side.specialStart3()

    async def _ready(self, player_id):
        self.game_start[player_id]["Ready"] = True

        if self.goldfish or all([start_info["Ready"] for start_info in self.game_start.values()]):
            await self._all_ready()

    async def _all_ready(self):
        for side in self.playing.values():
            await side.specialStart4()
        
        if self.goldfish_must_end_turn is not None:
            await self._on_end_turn(self.goldfish_must_end_turn)

    async def _on_end_turn(self, player_id):
        if player_id == self.current_turn:
            if self.firstTurn:
                self.firstTurn = False
            
            self.step = 1
            
            await self._send_message(self.players[player_id],"MESSAGE_ENDTURN")
            
            for player in self.playing:
                if player == player_id:
                    await self.playing[player].end_turn()
                else:
                    await self.playing[player].tell_player("Your Turn")
                    self.playing[player].is_turn = True
                    self.current_turn = player
            
            if self.goldfish and not self.players[player_id].dummy:
                dummy_player = [p_id for p_id in self.players if p_id != player_id][0]
                self.current_turn = dummy_player
                await self._on_end_turn(dummy_player)
    
    async def _start_rps(self):
        if not self.in_rps:
            self.in_rps = True
            self.rps = {p:-1 for p in self.players}
            for player in self.players.values():
                await player.tell("Game","Start Ingame RPS")
    
    async def _ingame_rps(self, player_id, choice):
        if player_id in self.rps and self.rps[player_id] == -1:
            self.rps[player_id] = choice

            if all([rps_choice!=-1 for rps_choice in self.rps.values()]):
                await self._ingame_rps_decide()

    async def _ingame_rps_decide(self):
        player1 = None
        player2 = None
        for player in self.players:
            if player1 is None:
                player1 = player
            else:
                player2 = player

        if self.rps[player1] == self.rps[player2]:
            for player in self.players:
                await self.players[player].tell("Game", "Ingame RPS Restart")
                self.rps[player]=-1
        elif self.rps[player1] - self.rps[player2] in (-2,1):
            await self.players[player1].tell("Game", "Ingame RPS Win")
            await self.players[player2].tell("Game", "Ingame RPS Loss")
            await self._send_message(self.players[player1],"MESSAGE_RPS")
            self.in_rps = False
        else:
            await self.players[player2].tell("Game", "Ingame RPS Win")
            await self.players[player1].tell("Game", "Ingame RPS Loss")
            await self._send_message(self.players[player2],"MESSAGE_RPS")
            self.in_rps = False
    
    async def game_win(self, winner, reason):
        for player in self.players.values():
            await player.tell("Game","Game Win",{"winner":winner.id, "reason":reason})
        for spectator in self.spectating:
            await spectator.tell("Game","Game Win",{"winner":winner.id, "reason":reason})
    
    async def tell_spectators(self, side, command, data=None):
        if data is None:
            data = {}
        data["player"] = side.player.id
        for spectator in self.spectating:
            await spectator.tell("Spectate Side",command,data)
    
    async def heartbeat(self):
        try:
            for player in self.players.values():
                await player.tell("Server", "Heartbeat")
        except WebSocketDisconnect:
            await self.close_game()
    
    async def _send_message(self, sender, message_code, translated=None, untranslated=None):
        if translated is None:
            translated = {}
        if untranslated is None:
            untranslated = {}
        
        for player in self.players.values():
            await player.tell("Game","Game Message",{"sender":sender.id,"message_code":message_code,"translated":translated,"untranslated":untranslated})
        for spectator in self.spectating:
            await spectator.tell("Game","Game Message",{"sender":sender.id,"message_code":message_code,"translated":translated,"untranslated":untranslated})
    
    async def call_command(self, player_id,command, data):
        match command:
            case "RPS":
                if "choice" in data:
                    await self._rps(player_id, data["choice"])
            case "Ingame RPS":
                if "choice" in data:
                    await self._ingame_rps(player_id, data["choice"])
            case "Turn Choice":
                if "choice" in data:
                    await self._on_choice_made(player_id, data["choice"])
            case "End Turn":
                await self._on_end_turn(player_id)
            case "Select Step":
                if "step" in data and self.current_turn == player_id and (not self.firstTurn or data["step"]!=5):
                    self.step == data["step"]
                    for player in self.players.values():
                        await player.tell("Game","Select Step",{"step":data["step"]})
                    for spectator in self.spectating:
                        await spectator.tell("Game","Select Step",{"step":data["step"]})
            
            case "Cosmetics":
                if "cosmetics" in data and not self.goldfish:
                    if data["cosmetics"] in self.cosmetics[player_id] and data["cosmetics"] != "passcode":
                        self.cosmetics[player_id][data["cosmetics"]] = True
                        await self.playing[player_id].tell_others("Cosmetics",{"cosmetics_type":data["cosmetics"]})
            
            case "Lose":
                if player_id in self.playing and "reason" in data:
                    await self.game_win(self.playing[player_id].opponent,data["reason"])
            
            case "Chat":
                if "message" in data and player_id in self.players:
                    for player in self.players.values():
                        await player.tell("Game","Chat",{"sender":player_id,"message":data["message"]})
                    for spectator in self.spectating:
                        await spectator.tell("Game","Chat",{"sender":player_id,"message":data["message"]})

            case _:
                pass
    
    async def to_dict(self):
        return {"step":self.step,"firstTurn":self.firstTurn,"players":{player.id: {"name":player.name, "side":await self.playing[player.id].to_dict()} for player in self.players.values()}}