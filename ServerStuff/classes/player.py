from random import sample
from fastapi import WebSocket, WebSocketDisconnect
from globals.data import get_data
from globals.live_data import get_all_players, get_manager, remove_player, set_player

class Player:
    def __init__(self, websocket: WebSocket | None = None):
        random_characters = get_data("random_characters")
        self.id = ''.join(sample(random_characters, 10))
        while self.id in get_all_players():
            self.id = ''.join(sample(random_characters, 10))
        
        if websocket is None:
            self.dummy = True
            self.name = "Goldfish Dummy"
        else:
            set_player(self.id, self)
            self.name = "Guest " + self.id
            get_manager().websocket_to_player[websocket] = self
            self.dummy = False

        self.websocket = websocket
        self.packet_number = 0

        self.lobby = None
        self.game = None

        self.goldfishing = False

        self.being_deleted=False
    
    async def tell(self, supertype, command, data=None):
        #Because the player deletion also ends up closing lobbies/games, which can send messages to players
        #Checking if the player is currently being deleted avoids sending messages to dead sockets
        if not self.being_deleted and not self.dummy:
            if data is None:
                data = {}
            try:
                await self.websocket.send_json({"supertype":supertype,"command":command,"data":data,"number":self.packet_number})
                self.packet_number += 1
            except WebSocketDisconnect:
                await self.remove()
    
    async def remove(self):
        self.being_deleted = True
        if self.lobby is not None:
            await self.lobby.remove_player(self.id)
        if self.game is not None and self in self.game.players.values():
            await self.game.close_game()
            #May want to do some shenanigans to allow reconnection
        if not self.dummy:
            get_manager().disconnect(self.websocket)
            remove_player(self.id)