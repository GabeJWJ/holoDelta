import json
from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.responses import RedirectResponse, StreamingResponse
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.gzip import GZipMiddleware
from traceback import format_exc
from classes.connection_manager import ConnectionManager
from classes.player import Player
from utils.card_utils import card_info
from globals.data import initialize, get_data
from globals.live_data import get_all_players, get_manager, initialize_manager
from utils.game_network_utils import update_numbers_all
from utils.game_utils import call_command
#import utils.azure_blob_storage as azb


# Initialize the data source
initialize()

random_characters = get_data("random_characters")
current_banlist = get_data("current_banlist")
en_current_banlist = get_data("en_current_banlist")
en_unreleased = get_data("en_unreleased")
unreleased = get_data("unreleased")
card_data = get_data("card_data")
bloom_levels = get_data("bloom_levels")
fudas = get_data("fudas")
identifier = get_data("identifier")
version = {"Client": get_data("client_version"), "Card": get_data("card_version")}

initialize_manager(ConnectionManager())

app = FastAPI()
app.mount("/game", StaticFiles(directory="Holodelta_web"), name="game")
app.add_middleware(GZipMiddleware, minimum_size=1000, compresslevel=9)

@app.get("/")
def index():
    return RedirectResponse(url="/game/index.html")

"""
BOUNTY -
This is the place where the zip gets fed through.
I have it sent as a downloadstream because I want to avoid downloading the full file and keeping it in memory when passing it
This exact thing MIGHT be fine to keep as a local file that gets returned, but the cosmetics NEED to use Blob Storage, so...
Cosmetics sharing probably also need it to be asynchronous, but let me know if I'm misinterpreting something.

Check utils/azure_blob_storage.py and the Setup region of Multiplayer.gd for context

@app.get("/cardData.zip")
async def get_card_data_archive():
    return StreamingResponse(await azb.get_card_data(), media_type="application/zip")
"""

@app.get("/version")
def get_current_version():
    return version

@app.get("/card/{card_id}")
def call_card_info(card_id: str):
    return card_info(card_id=card_id)

@app.get("/cardList")
def get_cards():
    return card_data

@app.get("/check")
def check_connection():
    return {"Success"}

@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    manager = get_manager()
    await manager.connect(websocket)
    try:
        player = Player(websocket)
        await player.tell("Server","Player Info",{"id":player.id, "name":player.name,"current":current_banlist,"en_current":en_current_banlist,"en_unreleased":en_unreleased,"unreleased":unreleased,"server_id":identifier})
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
        #manager.disconnect(websocket)
        await update_numbers_all()

