from fastapi import WebSocketDisconnect
from globals.data import get_data
from globals.live_data import get_all_games, set_game, remove_game
from classes.side import Side
from random import sample
from models.live_match import LiveMatch
from utils.game_network_utils import update_numbers_all
from utils.sql_utils import SessionLocal
from sqlalchemy.orm.attributes import flag_modified

class Game:
    def __init__(self, player1, player1deck, player2, player2deck, settings = None):
        random_characters = get_data("random_characters")
        self.id = ''.join(sample(random_characters, 10))
        while self.id in get_all_games():
            self.id = ''.join(sample(random_characters, 10))
        set_game(self.id, self)
        self.playing = {player1.id : Side(player1deck, self, player1, player2), player2.id : Side(player2deck, self, player2, player1)}
        self.players = {player1.id : player1, player2.id : player2}
        player1.game = self
        player2.game = self
        self.spectating = []
        self.settings = {} if settings is None else settings
        self.allow_spectators = self.settings["spectators"] if "spectators" in self.settings else False

        self.step = 5

        #Game Start Stuff
        self.game_start = {player1.id: {"RPS":-1, "Mulligan":False, "Ready":False}, player2.id: {"RPS":-1, "Mulligan":False, "Ready":False}}
        self.current_turn = -1
        self.firstTurn = True

        #Ingame RPS
        self.in_rps = False
        self.rps = {player1.id:-1, player2.id:-1}

        # Database update
        # write to db
        # Create a new session
        db = SessionLocal()
        match = LiveMatch(
            match_code=self.id,
            match_data={
                "players": [
                    {"id": player1.id, "name": player1.name, "side": "top" , "hp": 0, "life" : 0},
                    {"id": player2.id, "name": player2.name, "side": "bottom", "hp": 0, "life" : 0}
                ],
                "recently_played_card": None,
                "current_turn": self.current_turn,
                "step": self.step,
                "winner": None,
            }
        )
        db.add(match)
        db.commit()
        db.close()
    
    async def close_game(self):
        for player in self.players.values():
            await player.tell("Game","Close")
            player.game = None

        db = SessionLocal()
        # Find match session by game id
        item_to_delete = db.query(LiveMatch).filter(LiveMatch.match_code == self.id).first()

        # Delete it
        if item_to_delete:
            db.delete(item_to_delete)
            db.commit()
        else:
            print("Match not found")
        db.close()
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
        if player_id == self.current_turn:
            for player in self.playing:
                if (player == player_id) ^ (not choice):
                    self.current_turn = player
                    self.playing[player].is_turn = True
                    await self.players[player].tell("Game","Set Turn 1",{"is_turn":True})
                else:
                    self.playing[player].is_turn = False
                    await self.players[player].tell("Game","Set Turn 1",{"is_turn":False})

                await self.playing[player].specialStart2()

    async def _mulligan(self, player_id):
        self.game_start[player_id]["Mulligan"] = True

        if all([start_info["Mulligan"] for start_info in self.game_start.values()]):
            await self._all_mulligan()

    async def _all_mulligan(self):
        for side in self.playing.values():
            await side.specialStart3()

    async def _ready(self, player_id):
        self.game_start[player_id]["Ready"] = True

        if all([start_info["Ready"] for start_info in self.game_start.values()]):
            await self._all_ready()

    async def _all_ready(self):
        for side in self.playing.values():
            await side.specialStart4()

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
        # Update DB after call
        db = SessionLocal()

        # Fetch match
        match = db.query(LiveMatch).filter(LiveMatch.match_code == self.id).first()

        # Update nested JSON (example: set score)
        if match:
            player_ids = list(self.playing.keys())

            for id in player_ids:
                index = next((i for i, obj in enumerate(match.match_data["players"]) if obj["id"] == id), None)
                if index is not None:
                    result = match.match_data["players"][index]
                    # print("LIFE")
                    # for card in self.playing[id].life:
                    #     print(str(card.id) + " " + str(card.number))
                    # print("HOLOPOWER")
                    # for card in self.playing[id].holopower:
                    #     print(str(card.id) + " " + str(card.number))

                    result["life"] = len(self.playing[id].life)
                    # Somehow, non-holomem cards can still be put in holopower
                    # so a fallback value is required for this
                    result["hp"] = sum(getattr(card, "hp", 0) + getattr(card, "extra_hp", 0) for card in self.playing[id].holopower)

                    # replace the whole players object
                    match.match_data["players"][index] = result
                else:
                    print("player not found in match")
            # since its json, it has to be manually 
            # marked as modified
            flag_modified(match, "match_data")
            db.commit()
            db.refresh(match)

        db.close()      
        
    
    async def to_dict(self):
        return {"step":self.step,"firstTurn":self.firstTurn,"players":{player.id: {"name":player.name, "side":await self.playing[player.id].to_dict()} for player in self.players.values()}}