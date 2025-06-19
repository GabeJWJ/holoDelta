import json
from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.responses import RedirectResponse
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.gzip import GZipMiddleware
from traceback import format_exc
from classes.connection_manager import ConnectionManager
from classes.player import Player
from models.live_match import LiveMatch
from utils.card_utils import card_info
from globals.data import initialize, get_data
from globals.live_data import get_all_players, get_manager, initialize_manager
from utils.game_network_utils import update_numbers_all
from utils.game_utils import call_command
from utils.sql_utils import SessionLocal, initialize_database
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Initialize the data source
initialize()

random_characters = get_data("random_characters")
current_banlist = get_data("current_banlist")
unreleased = get_data("unreleased")
card_data = get_data("card_data")
bloom_levels = get_data("bloom_levels")
fudas = get_data("fudas")
identifier = get_data("identifier")

initialize_manager(ConnectionManager())
initialize_database()

app = FastAPI()
app.add_middleware(GZipMiddleware, minimum_size=1000, compresslevel=9)
app.mount("/game", StaticFiles(directory="Holodelta_web"), name="game")

@app.get("/")
def index():
    return RedirectResponse(url="/game/index.html")

@app.get("/card/{card_id}")
def call_card_info(card_id: str):
    return card_info(card_id=card_id)

@app.get("/cardList")
def get_cards():
    return card_data

@app.get("/check")
def check_connection():
    return {"Success"}


@app.get("/live-match/{game_id}")
def get_live_match_data(game_id: str):
    # Get the match data via game id
    db = SessionLocal()
    match = db.query(LiveMatch).filter(LiveMatch.match_code == game_id).first()
    db.close()
    if match:
        return match.match_data
    return {"error": "Match not found"}

@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    manager = get_manager()
    await manager.connect(websocket)
    try:
        player = Player(websocket)
        await player.tell("Server","Player Info",{"id":player.id, "name":player.name,"current":current_banlist,"unreleased":unreleased,"server_id":identifier})
        await update_numbers_all()
        while True:
            json_data = await websocket.receive_bytes()
            message = json.loads(str(json_data,'ascii'))
            try:
                if "supertype" in message and "command" in message and player.id in get_all_players():
                    command = message["command"]
                    data = message["data"]
                    match message["supertype"]:
                        case "Server":
                            await call_command(player.id,command, data)
                        case "Lobby":
                            if player.lobby is not None:
                                await player.lobby.call_command(player.id,command, data)
                        case "Game":
                            if player.game is not None:
                                await player.game.call_command(player.id,command, data)
                        case "Side":
                            if player.game is not None:
                                if player.id in player.game.playing:
                                    await player.game.playing[player.id].call_command(player.id,command, data)
                        case _:
                            pass
            except Exception:
                error_string = format_exc()
                await player.tell("Server","Error",{"error_text":error_string})
                print(error_string)
    except WebSocketDisconnect:
        await manager.websocket_to_player[websocket].remove()
        manager.disconnect(websocket)
        await update_numbers_all()


