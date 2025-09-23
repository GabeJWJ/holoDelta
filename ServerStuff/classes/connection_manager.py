from fastapi import WebSocket

#Stolen from https://fastapi.tiangolo.com/advanced/websockets/
class ConnectionManager:
    def __init__(self):
        self.active_connections: list[WebSocket] = []
        self.websocket_to_player = {}

    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.append(websocket)

    def disconnect(self, websocket: WebSocket):
        if websocket in self.active_connections:
            self.active_connections.remove(websocket)
        if websocket in self.websocket_to_player:
            del self.websocket_to_player[websocket]

    async def send_personal_message(self, message: str, websocket: WebSocket):
        await websocket.send_text(message)

    async def broadcast(self, message: str):
        for connection in self.active_connections:
            await connection.send_text(message)