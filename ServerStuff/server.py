import sqlite3 as sql
import json
from random import shuffle, sample, randrange
from string import ascii_lowercase, digits
from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.responses import RedirectResponse
from fastapi.staticfiles import StaticFiles
from enum import IntEnum

random_characters = ascii_lowercase+digits
with open('cards/banlists/current.json', 'r') as file:
    current_banlist = json.load(file)
with open('cards/banlists/unreleased.json', 'r') as file:
    unreleased = json.load(file)
with open('cards/cardData.json', 'r') as file:
    card_data = json.load(file)
bloom_levels = {-1:"LEVEL_SPOT",0:"LEVEL_DEBUT",1:"LEVEL_1",2:"LEVEL_2"}
fudas = ["DECK","CHEERDECK","ARCHIVE","HOLOPOWER"]

def card_info(card_id: str):
    return card_data[card_id] if card_id in card_data else {}

def check_legal(deck, banlist = None):
    if banlist is None:
        banlist = current_banlist

    result = {"legal":True,"reasons":[]}
    real_deck = {}

    if "oshi" in deck:
        oshi_info = deck["oshi"]
        if type(oshi_info) is list and len(oshi_info) == 2 and type(oshi_info[0]) is str and type(oshi_info[1]) is int:
            oshi_number = oshi_info[0]
            oshi_card = card_info(oshi_number)
            oshi_art = oshi_info[1]
            if "cardType" in oshi_card:
                if oshi_card["cardType"] == "Oshi":
                    if str(oshi_art) in oshi_card["cardArt"]:
                        if oshi_number in banlist:
                            result["legal"] = False
                            result["reasons"].append(["DECKERROR_BANNED",oshi_number])
                    else:
                        result["legal"] = False
                        result["reasons"].append(["DECKERROR_NOALTART",oshi_number])
                else:
                    result["legal"] = False
                    result["reasons"].append(["DECKERROR_FAKEOSHI",oshi_number])
            else:
                result["legal"] = False
                result["reasons"].append(["DECKERROR_FAKECARD",oshi_number])
        else:
            result["legal"] = False
            result["reasons"].append(["DECKERROR_OSHIBADFORMAT",""])
    else:
        result["legal"] = False
        result["reasons"].append(["DECKERROR_NOOSHI",""])
    
    if "deck" in deck:
        deck_info = deck["deck"]
        if type(deck_info) is list and all(type(x) is list and len(x) == 3 and type(x[0]) is str and type(x[1]) is int and type(x[2]) is int for x in deck_info):
            found_debut = False
            total_main = 0

            for main_row in deck_info:
                main_number = main_row[0]
                main_card = card_info(main_number)
                main_count = main_row[1]
                main_art = main_row[2]

                total_main += main_count

                if "cardType" in main_card:
                    if main_card["cardType"] in ["Holomem","Support"]:
                        if main_card["cardType"] == "Holomem" and main_card["level"] == 0:
                            found_debut = True
                        if main_card["cardLimit"] == -1 or main_count <= main_card["cardLimit"]:
                            if main_count > 0:
                                if str(main_art) in main_card["cardArt"]:
                                    if main_number in banlist:
                                        if banlist[main_number] == 0:
                                            result["legal"] = False
                                            result["reasons"].append(["DECKERROR_BANNED",main_number])
                                        elif banlist[main_number] < main_count:
                                            result["legal"] = False
                                            result["reasons"].append(["DECKERROR_RESTRICTED",main_number])
                                else:
                                    result["legal"] = False
                                    result["reasons"].append(["DECKERROR_NOALTART",main_number])
                            else:
                                result["legal"] = False
                                result["reasons"].append(["DECKERROR_NEGATIVEAMOUNT",main_number])
                        else:
                            result["legal"] = False
                            result["reasons"].append(["DECKERROR_OVERAMOUNT",main_number])
                    else:
                        result["legal"] = False
                        result["reasons"].append(["DECKERROR_FAKEMAIN",main_number])
                else:
                    result["legal"] = False
                    result["reasons"].append(["DECKERROR_FAKECARD",main_number])
            
            if found_debut:
                pass
            else:
                result["legal"] = False
                result["reasons"].append(["DECKERROR_NODEBUTS",""])
            
            if total_main < 50:
                result["legal"] = False
                result["reasons"].append(["DECKERROR_UNDERDECK",""])
            elif total_main > 50:
                result["legal"] = False
                result["reasons"].append(["DECKERROR_OVERDECK",""])
        else:
            result["legal"] = False
            result["reasons"].append(["DECKERROR_DECKBADFORMAT",""])
    else:
        result["legal"] = False
        result["reasons"].append(["DECKERROR_NODECK",""])
    
    if "cheerDeck" in deck:
        cheer_info = deck["cheerDeck"]
        if type(cheer_info) is list and all(type(x) is list and len(x) == 3 and type(x[0]) is str and type(x[1]) is int and type(x[2]) for x in cheer_info):
            total_cheer = 0

            for cheer_row in cheer_info:
                cheer_number = cheer_row[0]
                cheer_card = card_info(cheer_number)
                cheer_count = cheer_row[1]
                cheer_art = cheer_row[2]

                total_cheer += cheer_count

                if "cardType" in cheer_card:
                    if cheer_card["cardType"] == "Cheer":
                        if cheer_card["cardLimit"] == -1 or cheer_count <= cheer_card["cardLimit"]:
                            if cheer_count > 0:
                                if str(cheer_art) in cheer_card["cardArt"]:
                                    if cheer_number in banlist:
                                        if banlist[cheer_number] == 0:
                                            result["legal"] = False
                                            result["reasons"].append(["DECKERROR_BANNED",cheer_number])
                                        elif banlist[cheer_number] < cheer_count:
                                            result["legal"] = False
                                            result["reasons"].append(["DECKERROR_RESTRICTED",cheer_number])
                                else:
                                    result["legal"] = False
                                    result["reasons"].append(["DECKERROR_NOALTART",cheer_number])
                            else:
                                result["legal"] = False
                                result["reasons"].append(["DECKERROR_NEGATIVEAMOUNT",cheer_number])
                        else:
                            result["legal"] = False
                            result["reasons"].append(["DECKERROR_OVERAMOUNT",cheer_number])
                    else:
                        result["legal"] = False
                        result["reasons"].append(["DECKERROR_FAKECHEER",cheer_number])
                else:
                    result["legal"] = False
                    result["reasons"].append(["DECKERROR_FAKECARD",cheer_number])
            
            if total_cheer < 20:
                result["legal"] = False
                result["reasons"].append(["DECKERROR_UNDERCHEER",""])
            elif total_cheer > 20:
                result["legal"] = False
                result["reasons"].append(["DECKERROR_OVERCHEER",""])
        else:
            result["legal"] = False
            result["reasons"].append(["DECKERROR_CHEERBADFORMAT",""])
    else:
        result["legal"] = False
        result["reasons"].append(["DECKERROR_NOCHEER",""])
    
    if result["legal"]:
        real_deck = {"oshi":deck["oshi"],"deck":deck["deck"],"cheerDeck":deck["cheerDeck"]}
    
    return real_deck, result

#Stolen from https://fastapi.tiangolo.com/advanced/websockets/
class ConnectionManager:
    def __init__(self):
        self.active_connections: list[WebSocket] = []
        self.websocket_to_player = {}

    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.append(websocket)

    def disconnect(self, websocket: WebSocket):
        self.active_connections.remove(websocket)

    async def send_personal_message(self, message: str, websocket: WebSocket):
        await websocket.send_text(message)

    async def broadcast(self, message: str):
        for connection in self.active_connections:
            await connection.send_text(message)

manager = ConnectionManager()

players = {}
class Player:
    def __init__(self, websocket: WebSocket):
        self.id = ''.join(sample(random_characters, 10))
        while self.id in players:
            self.id = ''.join(sample(random_characters, 10))
        players[self.id] = self
        self.name = "Guest " + self.id
        self.websocket = websocket

        manager.websocket_to_player[websocket] = self

        self.lobby = None
        self.game = None

        self.being_deleted=False
    
    async def tell(self, supertype, command, data=None):
        #Because the player deletion also ends up closing lobbies/games, which can send messages to players
        #Checking if the player is currently being deleted avoids sending messages to dead sockets
        if not self.being_deleted:
            if data is None:
                data = {}
            await self.websocket.send_json({"supertype":supertype,"command":command,"data":data})
    
    async def remove(self):
        self.being_deleted = True
        if self.lobby is not None and self.lobby.host == self:
            await self.lobby.close_lobby()
        if self.game is not None and self in self.game.players.values():
            await self.game.close_game()
            #May want to do some shenanigans to allow reconnection
        del manager.websocket_to_player[self.websocket]
        del players[self.id]
        

class BloomCode(IntEnum):
    OK = 0
    Instant = 1
    Skip = 2
    No = 3

class Fuda(IntEnum):
    deck = 0
    cheerDeck = 1
    archive = 2
    holopower = 3

class Banlist(IntEnum):
    none = 0
    current = 1
    unreleased = 2
    custom = 99

class Card:
    def __init__(self, number, art_index, id):
        self.number = number
        self.art_index = art_index
        self.id = id
        self.tags = []
        self.attached = []
        self.onTopOf = []
        self.attachedTo = id
        self.rested = False
        self.faceDown = False
        self.trulyHidden = False
        self.onstage = False

        self.error = False

        init_info = card_info(number)
        try:
            self.cardType = init_info["cardType"]

            if "tags" in init_info:
                self.tags + init_info["tags"]
            match self.cardType:
                case "Oshi":
                    self.life = init_info["life"]
                    self.color = init_info["color"] if "color" in init_info else []
                    self.name = init_info["name"] if "name" in init_info else []
                    self.skill_cost = 0
                    self.spskill_cost = 0
                    for skill in init_info["skills"]:
                        if bool(skill["sp"]):
                            self.spskill_cost = skill["cost"]
                        else:
                            self.skill_cost = skill["cost"]
                case "Holomem":
                    self.bloomed_this_turn = False
                    self.level = init_info["level"]
                    self.buzz = bool(init_info["buzz"])
                    self.hp = init_info["hp"]
                    self.damage = 0
                    self.offered_damage = 0
                    self.extra_hp = 0
                    self.baton_pass_cost = init_info["batonPassCost"]
                    self.color = init_info["color"] if "color" in init_info else []
                    self.name = init_info["name"] if "name" in init_info else []
                    self.arts = {}
                    for art in init_info["arts"]:
                        cost_dict = {"White": 0, "Green": 0, "Red": 0, "Blue": 0, "Purple": 0, "Yellow": 0, "Any" : 0}
                        for chr in art["cost"]:
                            match chr:
                                case "W":
                                    cost_dict["White"] += 1
                                case "G":
                                    cost_dict["Green"] += 1
                                case "R":
                                    cost_dict["Red"] += 1
                                case "B":
                                    cost_dict["Blue"] += 1
                                case "P":
                                    cost_dict["Purple"] += 1
                                case "Y":
                                    cost_dict["Yellow"] += 1
                                case "N":
                                    cost_dict["Any"] += 1
                        self.arts[art["artIndex"]] = {"cost" : cost_dict, "damage" : art["damage"], "hasEffect" : bool(art["hasEffect"])}
                        if "advantage" in art:
                            self.arts[art["artIndex"]]["advantage"] = art["advantage"]
                    self.effects = []
                    if "effect" in init_info:
                        self.effects.append(init_info["effect"])
                case "Support":
                    self.limited = bool(init_info["limited"])
                    self.supportType = init_info["supportType"]
                case "Cheer":
                    if "color" in init_info:
                        self.cheer_color = init_info["color"]
                    else:
                        self.cheer_color = "COLORLESS"
        except:
            self.error = True
    
    async def is_color(self, color):
        if self.color:
            return color in self.color
        return False

    async def is_colorless(self):
        if self.color:
            return len(self.color) == 0
        return False

    async def has_name(self,name_check):
        if self.name:
            return name_check in self.name
        return False

    async def has_tag(self,tag_check):
        return tag_check in self.tags

    async def add_damage(self,amount):
        self.damage += amount
        if self.damage < 0:
            self.damage = 0
        if self.damage > 999:
            self.damage = 999

    async def clear_damage(self):
        self.damage = 0

    async def add_extra_hp(self,amount):
        self.extra_hp += amount
        if self.extra_hp < 0:
            self.extra_hp = 0
        if self.extra_hp > 999:
            self.extra_hp = 999

    async def clear_extra_hp(self):
        self.extra_hp = 0

    async def update_attached(self):
        for attached_card in self.attached:
            attached_card.attachedTo = self.id

    async def rest(self):
        if self.rested:
            pass
        else:
            self.rested = True
            
            for card in self.onTopOf:
                await card.rest()
            
            await self.update_attached()
            
    async def unrest(self):
        if not self.rested:
            pass
        else:
            self.rested = False
            
            for card in self.onTopOf:
                await card.unrest()
            
            await self.update_attached()

    async def has_name_in_common(self,other_card):
        for potentialName in self.name:
            if await other_card.has_name(potentialName):
                return True
        return False

    async def can_bloom(self,other_card):
        if self.cardType == "Holomem" and self.level > 0 and other_card.cardType == "Holomem" and other_card.level >=0 and await self.has_name_in_common(other_card) and other_card.damage < self.hp:
            if other_card.level <= self.level:
                difference = self.level - other_card.level
                if difference <= 1:
                    if other_card.bloomed_this_turn:
                        return BloomCode.Instant
                    else:
                        return BloomCode.OK
                else:
                    return BloomCode.Skip
        return BloomCode.No

    async def playOnTopOf(self,other_card):
        if other_card.rested:
            await self.rest()
        
        self.onTopOf.append(other_card)
        self.onTopOf += other_card.onTopOf
        other_card.onTopOf = []
        for att in other_card.attached:
            await self.attach(att)
        other_card.attached = []
        await other_card.clear_damage()
        await other_card.clear_extra_hp()

    async def bloom(self,other_card):
        self.damage = other_card.damage
        self.extra_hp = other_card.extra_hp
        await self.playOnTopOf(other_card)
        self.bloomed_this_turn = True
        self.onstage = True

    async def unbloom(self):
        if len(self.onTopOf) == 0:
            return
        else:
            newCard = self.onTopOf.pop(0)
            newCard.onTopOf = self.onTopOf
            self.onTopOf = []
            for attachCard in self.attached:
                await newCard.attach(attachCard)
            self.attached = []
            newCard.damage = self.damage
            newCard.extra_hp = self.extra_hp
            newCard.onstage = True
            await self.clear_damage()
            await self.clear_extra_hp()
            await self.unrest()
            self.onstage = False

    async def attach(self,other_card):
        await other_card.unrest()
        self.attached.append(other_card)
        await self.update_attached()

    async def flipDown(self):
        if self.faceDown:
            pass
        else:
            self.faceDown = True

    async def flipUp(self):
        if not self.faceDown:
            pass
        else:
            self.faceDown = False
            self.trulyHidden = False

    async def trulyHide(self):
        if self.trulyHidden:
            pass
        else:
            await self.flipDown()
            self.trulyHidden = True
    
    async def to_dict(self):
        result = {"cardID" : self.id, "cardNumber" : self.number, "cardType":self.cardType, "artIndex" : self.art_index, "tags" : self.tags, "attachedTo" : self.attachedTo, "rested" : self.rested, "faceDown" : self.faceDown, "trulyHidden" : self.trulyHidden, "onstage" : self.onstage}
        result["attached"] = [await att.to_dict() for att in self.attached]
        result["onTopOf"] = [await oto.to_dict() for oto in self.onTopOf]

        match self.cardType:
            case "Oshi":
                result["life"] = self.life
                result["color"] = self.color
                result["name"] = self.name
                result["skill_cost"] = self.skill_cost
                result["spskill_cost"] = self.spskill_cost
            case "Holomem":
                result["bloomed_this_turn"] = self.bloomed_this_turn
                result["level"] = self.level
                result["buzz"] = self.buzz
                result["hp"] = self.hp
                result["damage"] = self.damage
                result["extra_hp"] = self.extra_hp
                result["baton_pass_cost"] = self.baton_pass_cost
                result["color"] = self.color
                result["name"] = self.name
                result["arts"] = self.arts
                result["effects"] = self.effects
            case "Support":
                result["limited"] = self.limited
                result["supportType"] = self.supportType
            case "Cheer":
                result["color"] = self.cheer_color
        
        return result

class Side:
    def __init__(self, deck, game, player, opponent):
        self.game = game
        self.player = player
        self.opponent = opponent
        self.cards = []
        self.deck = []
        self.cheer_deck = []
        self.archive = []
        self.holopower = []
        self.zones = {"Center":-1, "Collab":-1, "Back1":-1, "Back2":-1, "Back3":-1, "Back4":-1, "Back5":-1, "Back6":-1}
        self.hand = []
        self.life = []
        self.revealed = []
        self.playing = None

        self.in_mulligans = True
        self.preliminary_phase = True
        self.penalty = 0
        self.preliminary_holomem_in_center = False
        self.can_do_things = False
        self.forced_mulligan_cards = []

        self.is_turn = False
        self.first_turn = True
        self.player1 = False
        self.collabed = False
        self.used_limited = False
        self.used_baton_pass = False
        self.used_oshi_skill = False
        self.used_sp_oshi_skill = False
        self.can_undo_shuffle_hand = None

        self.oshi = Card(deck["oshi"][0],deck["oshi"][1],0)
        self.cards.append(self.oshi)

        for info in deck["deck"]:
            for i in range(info[1]):
                newCard = Card(info[0],info[2],len(self.cards))
                self.cards.append(newCard)
                self.deck.append(newCard)

        for info in deck["cheerDeck"]:
            for i in range(info[1]):
                newCard = Card(info[0],info[2],len(self.cards))
                self.cards.append(newCard)
                self.cheer_deck.append(newCard)
        
        shuffle(self.deck)
        shuffle(self.cheer_deck)
    
    async def specialStart2(self):
        await self.draw(7)

        await self.tell_player("Mulligan",{"forced":not await self.hasLegalHand()})

    async def yes_mulligan(self):
        await self.game._send_message(self.player,"MESSAGE_MULLIGAN")
        
        list_of_ids = []
        for hand_card in self.hand:
            list_of_ids.append(hand_card.id)
        for hand_id in list_of_ids:
            await self.add_to_fuda(hand_id,Fuda.deck)
            await self.remove_from_hand(hand_id)
        shuffle(self.deck)
        await self.tell_all("Shuffle Fuda", {"fuda":int(Fuda.deck)})
        
        await self.draw(7-self.penalty)
        
        if await self.hasLegalHand():
            await self.no_mulligan()
        elif self.penalty == 6:
            await self.game.game_win(self.opponent,"WINREASON_MULLIGAN")
        else:
            await self.tell_player("Mulligan",{"forced":True})
            self.penalty += 1
            if self.penalty > 1:
                self.forced_mulligan_cards.append(None)
            for hand_card in self.hand:
                self.forced_mulligan_cards.append(await hand_card.to_dict())

    async def no_mulligan(self):
        await self.tell_player("No Mulligan")

        await self.game._mulligan(self.player.id)

    async def specialStart3(self):
        forced_mulligan_cards = self.game.playing[self.opponent.id].forced_mulligan_cards
        await self.tell_player("Mulligan Done", {"forced_mulligan_cards":forced_mulligan_cards})
        self.can_do_things = True
        self.in_mulligans = False

    async def specialStart4(self):
        await self.oshi.flipUp()

        oshi_info = await self.oshi.to_dict()

        zone_info = {}
        
        for zone in self.zones:
            if self.zones[zone] != -1:
                await self.cards[self.zones[zone]].flipUp()
                zone_info[zone] = await self.cards[self.zones[zone]].to_dict()
        
        self.preliminary_phase = False
        
        for i in range(self.oshi.life):
            newLife = self.cheer_deck.pop(0)
            self.life.append(newLife)
            await newLife.trulyHide()
            await newLife.rest()
        
        life_info = [lif.id for lif in self.life]
        
        await self.tell_player("All Ready",{"life":life_info,"is_turn":self.is_turn})
        await self.tell_others("All Ready",{"oshi":oshi_info,"zones":zone_info})

    async def hasLegalHand(self):
        for actualCard in self.hand:
            if actualCard.cardType == "Holomem" and actualCard.level == 0:
                return True
        return False

    async def draw(self, x=1):
        for i in range(x):
            new_card = self.deck[0].id
            await self.remove_from_fuda(new_card, Fuda.deck)
            await self.add_to_hand(new_card)
        
        if x == 1:
            await self.game._send_message(self.player,"MESSAGE_DRAW")
        else:
            await self.game._send_message(self.player,"MESSAGE_DRAWX",{},{"amount":x})

    async def mill(self, from_fuda,to_fuda,x=1):
        match from_fuda:
            case Fuda.deck:
                actualFuda = self.deck
            case Fuda.cheerDeck:
                actualFuda = self.cheer_deck
            case Fuda.archive:
                actualFuda = self.archive
            case Fuda.holopower:
                actualFuda = self.holopower
            case _:
                actualFuda = self.deck
        
        for i in range(x):
            new_card = actualFuda[0].id
            await self.remove_from_fuda(new_card, from_fuda)
            await self.add_to_fuda(new_card,to_fuda)
        
        if x == 1:
            await self.game._send_message(self.player,"MESSAGE_MILL",{"from":fudas[int(from_fuda)],"to":fudas[int(to_fuda)]})
        else:
            await self.game._send_message(self.player,"MESSAGE_MILLX",{"from":fudas[int(from_fuda)],"to":fudas[int(to_fuda)]},{"amount":x})

    async def find_what_zone(self, card_id):
        for possible_zone in self.zones:
            if self.zones[possible_zone] == card_id:
                return possible_zone

    async def set_zone_card(self, zone, new_card):
        for possible_zone in self.zones:
            if possible_zone == zone:
                self.zones[possible_zone] = new_card

    async def remove_old_card(self, old_card,leavingField = False):
        if leavingField:
            await self.tell_all("Card Left Field",{"card_id":old_card})
            actualCard = self.cards[old_card]
            await actualCard.unrest()
            actualCard.attached = []
            actualCard.onTopOf = []
            actualCard.onstage = False
            await actualCard.clear_damage()
            await actualCard.clear_extra_hp()
            if old_card in self.revealed:
                self.revealed.remove(old_card)
            if old_card == self.playing:
                self.playing = None
        for zone in self.zones:
            if self.zones[zone] == old_card:
                self.zones[zone] = -1
        

    async def remove_from_hand(self, old_card, hidden=False):
        removed_card = None

        for index in range(len(self.hand)):
            if self.hand[index].id == old_card:
                removed_card = self.hand.pop(index)
                break
        
        await self.tell_player("Remove From Hand", {"card_id":old_card,"hidden":hidden})

        await self.tell_others("Remove From Hand")

    async def add_to_hand(self, new_card):
        cardToGo = self.cards[new_card]
        
        cardToGo.attached.reverse()
        cardToGo.onTopOf.reverse()
        for newCard in cardToGo.attached:
            await self.add_to_hand(newCard.id)
        for newCard in cardToGo.onTopOf:
            await self.add_to_hand(newCard.id)
        
        self.hand.append(self.cards[new_card])


        await self.tell_player("Add To Hand", {"card_id":new_card})
        await self.tell_others("Add To Hand")

    async def remove_from_fuda(self, card_id, from_fuda):
        match from_fuda:
            case Fuda.deck:
                list_of_cards = self.deck
            case Fuda.cheerDeck:
                list_of_cards = self.cheer_deck
            case Fuda.archive:
                list_of_cards = self.archive
            case Fuda.holopower:
                list_of_cards = self.holopower
            case _:
                list_of_cards = from_fuda #Really gross - please don't intentionally use this
                
        for i in range(len(list_of_cards)):
            if list_of_cards[i].id == card_id:
                list_of_cards.pop(i)
                break
                
        await self.tell_player("Remove From Fuda",{"card_id":card_id,"from_fuda":int(from_fuda)})
        await self.tell_others("Remove From Fuda",{"from_fuda":int(from_fuda), "removed_card":await self.cards[card_id].to_dict() if from_fuda == Fuda.archive else None})

    async def remove_from_attached(self, card_id, attached):
        actualCard = self.cards[card_id]

        if actualCard in attached.attached:
            attached.attached.remove(actualCard)
            actualCard.attachedTo = card_id
        elif actualCard in attached.onTopOf:
            attached.onTopOf.remove(actualCard)
            actualCard.attachedTo = card_id
        
        await self.tell_all("Remove From Attached", {"card_id":card_id, "attached_id":attached.id})

    async def add_to_fuda(self, card_id,to_fuda,bottom=False):

        match to_fuda:
            case Fuda.deck:
                list_of_cards = self.deck
            case Fuda.cheerDeck:
                list_of_cards = self.cheer_deck
            case Fuda.archive:
                list_of_cards = self.archive
            case Fuda.holopower:
                list_of_cards = self.holopower
            case _:
                list_of_cards = to_fuda #Really gross - please don't intentionally use this

        new_position = 0
        if bottom:
            new_position = len(list_of_cards)
        cardToGo = self.cards[card_id]
        
        cardToGo.attached.reverse()
        cardToGo.onTopOf.reverse()
        for newCard in cardToGo.attached:
            await self.add_to_fuda(newCard.id,to_fuda,bottom)
            newCard.attachedTo = newCard.id
        for newCard in cardToGo.onTopOf:
            await self.add_to_fuda(newCard.id,to_fuda,bottom)
            newCard.attachedTo = newCard.id
        
        list_of_cards.insert(new_position,cardToGo)

        moved_card = (await cardToGo.to_dict()) if to_fuda == Fuda.archive else None
        
        await self.tell_player("Add To Fuda",{"card_id":card_id,"to_fuda":int(to_fuda),"bottom":bottom})
        await self.tell_others("Add To Fuda",{"to_fuda":int(to_fuda),"moved_card":moved_card})

    async def first_unoccupied_back_zone(self, card_id = None):
        result = None
        for zone in self.zones:
            if zone == "Center" or zone == "Collab": #We're looking for back zones
                pass
            elif self.zones[zone] == -1 and result is None: #Found an empty zone (and haven't already found one)
                result = zone[0]
            #Dedeft but like... what if, ya know?
            elif card_id is not None and self.zones[zone] == card_id: #We also check to make sure the specific card isn't on the backrow, to avoid having "move to back" show up on a card already in the back
                return False
        if result:
            return result
        else:
            return False

    async def all_unoccupied_back_zones(self):
        result = []
        for zone in self.zones:
            if zone == "Center" or zone == "Collab":
                pass
            elif self.zones[zone] == -1:
                result.append(zone)
        
        return result

    async def all_occupied_zones(self, only_back=False,except_id=None):
        result = []
        for zone in self.zones:
            if only_back and (zone == "Center" or zone == "Collab"):
                pass
            elif except_id is not None and self.zones[zone] == except_id:
                pass
            elif self.zones[zone] != -1:
                result.append(zone)
        
        return result

    async def all_bloomable_zones(self, card_check):
        result = {BloomCode.OK:[],BloomCode.Instant:[],BloomCode.Skip:[]}
        for zone in self.zones:
            if self.zones[zone] != -1:
                bloom_code = card_check.can_bloom(self.cards[self.zones[zone]])
                if bloom_code != BloomCode.No:
                    result[bloom_code].append(zone)
        
        return result

    async def move_card_to_zone(self, card_id, zone, facedown=False):
        self.cards[card_id].onstage = True
        
        if await self.find_what_zone(card_id):
            await self.remove_old_card(card_id)
        
        self.zones[zone] = card_id

        await self.tell_player("Move Card To Zone",{"card_id":card_id,"zone":zone})
        await self.tell_others("Move Card To Zone",{"card":{} if facedown else await self.cards[card_id].to_dict(),"zone":zone,"facedown":facedown})

    async def switch_cards_in_zones(self, zone_1,zone_2):
        card1 = self.cards[self.zones[zone_1]]
        card2 = self.cards[self.zones[zone_2]]
        
        self.zones[zone_1] = card2.id
        self.zones[zone_2] = card1.id

        await self.tell_all("Switch Cards In Zones", {"zone_1":zone_1,"zone_2":zone_2})

    async def bloom_on_zone(self, card_to_bloom, zone_to_bloom):
        bloomee = self.cards[self.zones[zone_to_bloom]]
        await card_to_bloom.bloom(bloomee)
        self.zones[zone_to_bloom] = card_to_bloom.id
        await self.remove_from_hand(card_to_bloom.id)

        await self.tell_player("Bloom",{"card_to_bloom":card_to_bloom.id, "zone_to_bloom":zone_to_bloom})
        await self.tell_others("Bloom", {"card":await card_to_bloom.to_dict(), "zone_to_bloom":zone_to_bloom})

        await self.game._send_message(self.player,"MESSAGE_BLOOM",{"fromName":bloomee.number + "_NAME","fromLevel":bloom_levels[bloomee.level],
                                                            "toName":card_to_bloom.number + "_NAME","toLevel":bloom_levels[card_to_bloom.level]},{"fromZone":zone_to_bloom})
    
    async def end_turn(self):
        if self.is_turn:
            self.first_turn = False
            self.used_limited = False
            self.collabed = False
            self.used_baton_pass = False
            self.used_oshi_skill = False
            self.can_undo_shuffle_hand = None
            for actualCard in self.cards:
                if actualCard.cardType == "Holomem":
                    actualCard.bloomed_this_turn = False

    async def popup_command(self, command_id, data):
        currentCard = data["currentCard"] if "currentCard" in data else None
        match command_id:
            case 0: #Rest
                if currentCard is not None:
                    await self.cards[currentCard].rest()
                    await self.tell_all("Rest",{"card_id":currentCard})
            case 1: #Unrest
                if currentCard is not None:
                    await self.cards[currentCard].unrest()
                    await self.tell_all("Unrest",{"card_id":currentCard})
            case 2: #Archive
                if currentCard is not None:
                    actualCard = self.cards[currentCard]
                    await self.game._send_message(self.player,"MESSAGE_STAGE_ARCHIVE",{"fromName":actualCard.number + "_NAME"},{"fromZone":await self.find_what_zone(currentCard)})
                    await self.add_to_fuda(currentCard,Fuda.archive)
                    await self.remove_old_card(currentCard,True)
                    if self.playing == currentCard:
                        self.playing = None
            case 3: #Return to Hand
                if currentCard is not None:
                    actualCard = self.cards[currentCard]
                    await self.game._send_message(self.player,"MESSAGE_STAGE_HAND",{"fromName":actualCard.number+"_NAME"},{"fromZone":await self.find_what_zone(currentCard)})
                    await actualCard.clear_damage()
                    await actualCard.clear_extra_hp()
                    await actualCard.unrest()
                    await self.add_to_hand(currentCard)
                    await self.remove_old_card(currentCard,True)
            case 4: #Move to Center
                if currentCard is not None:
                    await self.game._send_message(self.player,"MESSAGE_STAGE_CENTER",{"fromName":self.cards[currentCard].number + "_NAME"},{"fromZone":await self.find_what_zone(currentCard)})
                    await self.move_card_to_zone(currentCard,"Center")
            case 6: #Collab
                if currentCard is not None:
                    await self.game._send_message(self.player,"MESSAGE_STAGE_COLLAB",{"fromName":self.cards[currentCard].number + "_NAME"},{"fromZone":await self.find_what_zone(currentCard)})
                    await self.move_card_to_zone(currentCard,"Collab")
                    if len(self.deck) > 0:
                        await self.mill(Fuda.deck,Fuda.holopower)
                    self.collabed = True
                    await self.tell_player("Collab")
            case 9: #Move to Collab
                if currentCard is not None:
                    await self.game._send_message(self.player,"MESSAGE_STAGE_MOVECOLLAB",{"fromName":self.cards[currentCard].number + "_NAME"},{"fromZone":await self.find_what_zone(currentCard)})
                    await self.move_card_to_zone(currentCard,"Collab")
            case 15: #Unbloom
                if currentCard is not None:
                    await self.tell_all("Unbloom",{"card_to_unbloom":currentCard})
                    actualCard = self.cards[currentCard]
                    newCard = actualCard.onTopOf[0]
                    await self.game._send_message(self.player,"MESSAGE_STAGE_UNBLOOM",{"fromName":actualCard.number + "_NAME","toName":newCard.number + "_NAME"},{"fromZone":await self.find_what_zone(currentCard)})
                    await actualCard.unbloom()
                    for zone in self.zones:
                        if self.zones[zone] == currentCard:
                            self.zones[zone] = newCard.id
                    await self.remove_old_card(currentCard,True)
                    await self.add_to_hand(currentCard)
            case 20: #Archive Support in Play
                if currentCard is not None:
                    await self.add_to_fuda(currentCard,Fuda.archive)
                    await self.remove_old_card(currentCard,True)
                    self.playing = None
            case 21: #Add Revealed Card to Hand
                if currentCard is not None:
                    await self.game._send_message(self.player,"MESSAGE_REVEALED_HAND",{"cardName":self.cards[currentCard].number + "_NAME"})
                    await self.remove_old_card(currentCard,True)
                    await self.add_to_hand(currentCard)
            case 23: #Send Revealed Card to Top of Deck
                if currentCard is not None:
                    await self.game._send_message(self.player,"MESSAGE_REVEALED_TOPDECK",{"cardName":self.cards[currentCard].number + "_NAME"})
                    await self.remove_old_card(currentCard,True)
                    await self.add_to_fuda(currentCard, Fuda.deck)
            case 24: #Send Revealed Card to Bottom of Deck
                if currentCard is not None:
                    await self.game._send_message(self.player,"MESSAGE_REVEALED_BOTTOMDECK",{"cardName":self.cards[currentCard].number + "_NAME"})
                    await self.remove_old_card(currentCard,True)
                    await self.add_to_fuda(currentCard, Fuda.deck, True)
            case 25: #Send Revealed Card to Archive
                if currentCard is not None:
                    await self.game._send_message(self.player,"MESSAGE_REVEALED_ARCHIVE",{"cardName":self.cards[currentCard].number + "_NAME"})
                    await self.remove_old_card(currentCard,True)
                    await self.add_to_fuda(currentCard, Fuda.archive)
            case 30: #Reveal and Attach Life
                if currentCard is not None:
                    cheerCard = self.cards[currentCard]
                    if cheerCard == self.life[0]:
                        self.life.remove(cheerCard)
                        await cheerCard.flipUp()
                        await self.tell_player("Reveal Life", {"card_id":cheerCard.id})
                        await self.tell_others("Reveal Life", {"card":await cheerCard.to_dict()})
            case 70: #Oshi Skill
                if currentCard is not None and self.cards[currentCard].skill_cost >= 0:
                    self.used_oshi_skill = True
                    await self.game._send_message(self.player,"MESSAGE_OSHISKILL",{"skillName":self.cards[currentCard] + "_SKILL_NAME"})
                    await self.mill(Fuda.holopower,Fuda.archive,self.cards[currentCard].skill_cost)
            case 71: #SP Oshi Skill
                if currentCard is not None and self.cards[currentCard].spskill_cost >= 0:
                    self.used_sp_oshi_skill = True
                    await self.tell_others("Used SP Skill")
                    await self.game._send_message(self.player,"MESSAGE_OSHISKILL_SP",{"skillName":self.cards[currentCard] + "_SPSKILL_NAME"})
                    await self.mill(Fuda.holopower,Fuda.archive,self.cards[currentCard].spskill_cost)
            
            case 102: #Play Hidden to Center
                if currentCard is not None:
                    await self.move_card_to_zone(currentCard,"Center",True)
                    await self.remove_from_hand(currentCard,True)
                    self.preliminary_holomem_in_center = True
            case 110: #Return to top of deck
                if currentCard is not None:
                    await self.game._send_message(self.player,"MESSAGE_HAND_TOPDECK")
                    await self.add_to_fuda(currentCard,Fuda.deck)
                    await self.remove_from_hand(currentCard)
                    self.can_undo_shuffle_hand = None
            case 111: #Return to bottom of deck
                if currentCard is not None:
                    await self.game._send_message(self.player,"MESSAGE_HAND_BOTTOMDECK")
                    await self.add_to_fuda(currentCard,Fuda.deck,-1)
                    await self.remove_from_hand(currentCard)
                    self.can_undo_shuffle_hand = None
            case 112: #Archive
                if currentCard is not None:
                    await self.game._send_message(self.player,"MESSAGE_HAND_ARCHIVE",{"cardName":self.cards[currentCard].number + "_NAME"})
                    await self.add_to_fuda(currentCard,Fuda.archive)
                    await self.remove_from_hand(currentCard)
            case 113: #Holopower
                if currentCard is not None:
                    await self.game._send_message(self.player,"MESSAGE_HAND_HOLOPOWER")
                    await self.add_to_fuda(currentCard,Fuda.holopower)
                    await self.remove_from_hand(currentCard)
            case 114: #Reveal from Hand
                if currentCard is not None:
                    actualCard = self.cards[currentCard]
                    await self.game._send_message(self.player,"MESSAGE_HAND_REVEAL",{"cardName":actualCard.number + "_NAME"})

                    self.revealed.append(currentCard)
                    await self.remove_from_hand(currentCard)
                    await self.tell_player("Reveal",{"card_id":currentCard})
                    await self.tell_others("Reveal",{"card":await actualCard.to_dict()})
            case 120: #Play Support
                if currentCard is not None:
                    actualCard = self.cards[currentCard]
                    await self.game._send_message(self.player,"MESSAGE_HAND_SUPPORT_PLAY",{"cardName":actualCard.number + "_NAME"})
                    if actualCard.limited:
                        self.used_limited = True
                    await self.remove_from_hand(currentCard)

                    await self.tell_player("Play Support",{"card_id":currentCard})
                    await self.tell_others("Play Support",{"card":await actualCard.to_dict()})

                    self.playing = currentCard

            case 200: #Draw
                await self.draw()
                self.can_undo_shuffle_hand = None
            case 202: #Mill
                await self.mill(Fuda.deck,Fuda.archive)
                self.can_undo_shuffle_hand = None
            case 204: #Holopower
                await self.mill(Fuda.deck,Fuda.holopower)
                self.can_undo_shuffle_hand = None
            case 205: #Reveal Top Card From Deck
                actualCard = self.deck[0]
                currentCard = actualCard.id
                await self.game._send_message(self.player,"MESSAGE_FUDA_REVEAL",{"cardName":actualCard.number + "_NAME","fromFuda":"DECK"})
                await self.remove_from_fuda(currentCard,Fuda.deck)

                self.revealed.append(currentCard)
                self.can_undo_shuffle_hand = None
                await self.tell_player("Reveal",{"card_id":currentCard})
                await self.tell_others("Reveal",{"card":await actualCard.to_dict()})
            case 250: #Shuffle Hand Into Deck
                await self.game._send_message(self.player,"MESSAGE_DECK_MULLIGAN")
                list_of_ids = []
                for hand_card in self.hand:
                    list_of_ids.append(hand_card.id)
                self.can_undo_shuffle_hand = list_of_ids
                for hand_id in list_of_ids:
                    await self.add_to_fuda(hand_id,Fuda.deck)
                    await self.remove_from_hand(hand_id)
                
                await self.tell_all("Shuffle Fuda", {"fuda":int(Fuda.deck)})

                shuffle(self.deck)
            case 251: #Unshuffle Hand Into Deck
                await self.game._send_message(self.player,"MESSAGE_DECK_UNDOMULLIGAN")
                for hand_id in self.can_undo_shuffle_hand:
                    await self.add_to_hand(hand_id)
                    await self.remove_from_fuda(hand_id,Fuda.deck)
            case 296: #Start RPS
                await self.game._start_rps()
            case 298: #Search Deck
                await self.game._send_message(self.player,"MESSAGE_DECK_SEARCH")
                await self.tell_others("Look At",{"fuda":int(Fuda.deck)})
            case 299: #Shuffle
                await self.game._send_message(self.player,"MESSAGE_DECK_SHUFFLE")

                await self.tell_all("Shuffle Fuda", {"fuda":int(Fuda.deck)})

                shuffle(self.deck)
            
            case 300: #Reveal and Attach Cheer
                actualCard = self.cheer_deck[0]
                currentCard = actualCard.id
                await self.remove_from_fuda(currentCard, Fuda.cheerDeck)
                await self.tell_player("Reveal Cheer",{"card_id":currentCard})
                await self.tell_others("Reveal Cheer",{"card":await actualCard.to_dict()})
            case 398: #Search Cheer Deck
                await self.game._send_message(self.player,"MESSAGE_CHEERDECK_SEARCH")
                await self.tell_others("Look At",{"fuda":int(Fuda.cheerDeck)})
            case 399: #Shuffle
                await self.game._send_message(self.player,"MESSAGE_CHEERDECK_SHUFFLE")

                await self.tell_all("Shuffle Fuda", {"fuda":int(Fuda.cheerDeck)})

                shuffle(self.cheer_deck)
            
            case 500: #Holopower to Archive
                await self.mill(Fuda.holopower,Fuda.archive)
            case 510: #Holopower to top of deck
                await self.mill(Fuda.holopower,Fuda.deck)
            case 598: #Search Holopower
                await self.game._send_message(self.player,"MESSAGE_HOLOPOWER_SEARCH")
                await self.tell_others("Look At",{"fuda":int(Fuda.holopower)})
            case 599: #Shuffle
                await self.game._send_message(self.player,"MESSAGE_HOLOPOWER_SHUFFLE")

                await self.tell_all("Shuffle Fuda", {"fuda":int(Fuda.holopower)})

                shuffle(self.holopower)
            case _:
                pass
    
    async def popup_from_fuda_command(self, command_id, data):
        currentCard = data["currentCard"]
        currentFuda = Fuda(data["currentFuda"])
        
        match command_id:
            case 603: #To Life
                actualCard = self.cards[currentCard]
                if len(self.life) < 6 and actualCard.cardType == "Cheer":
                    await self.game._send_message(self.player,"MESSAGE_FUDA_LIFE",{"fromFuda":fudas[int(currentFuda)]})
                    await self.remove_from_fuda(currentCard,currentFuda)
                    
                    self.life.insert(0, actualCard)
                    await actualCard.trulyHide()
                    await actualCard.rest()

                    await self.tell_player("Remove From List",{"card_id":currentCard})
                    await self.tell_player("To Life",{"card_id":currentCard})
                    await self.tell_others("To Life")

            case 630: #Reveal Card From Fuda
                actualCard = self.cards[currentCard]
                if currentFuda == Fuda.holopower:
                    await self.game._send_message(self.player,"MESSAGE_HOLOPOWER_REVEAL",{"cardName":actualCard.number + "_NAME"})
                else:
                    await self.game._send_message(self.player,"MESSAGE_FUDA_REVEAL",{"cardName":actualCard.number + "_NAME","fromFuda":fudas[int(currentFuda)]})
                await self.remove_from_fuda(currentCard,currentFuda)
                self.revealed.append(currentCard)
                await self.tell_player("Reveal",{"card_id":currentCard})
                await self.tell_others("Reveal",{"card":await actualCard.to_dict()})

                await self.tell_player("Remove From List",{"card_id":currentCard})

                self.can_undo_shuffle_hand = None

            case 650: #Add to Hand
                if currentFuda == Fuda.archive:
                    await self.game._send_message(self.player,"MESSAGE_ARCHIVE_HAND",{"cardName":self.cards[currentCard].number + "_NAME"})
                elif currentFuda == Fuda.holopower:
                    await self.game._send_message(self.player,"MESSAGE_HOLOPOWER_HAND")
                else:
                    await self.game._send_message(self.player,"MESSAGE_FUDA_HAND",{"fromFuda":fudas[int(currentFuda)]})
                
                await self.remove_from_fuda(currentCard,currentFuda)
                await self.cards[currentCard].unrest()
                await self.add_to_hand(currentCard)
                
                await self.tell_player("Remove From List",{"card_id":currentCard})

                self.can_undo_shuffle_hand = None
                
            case 651: #Return to top of deck

                match currentFuda:
                    case Fuda.archive:
                        await self.game._send_message(self.player,"MESSAGE_ARCHIVE_TOPDECK",{"cardName":self.cards[currentCard].number + "_NAME"})
                    case Fuda.deck:
                        await self.game._send_message(self.player,"MESSAGE_DECK_TOPDECK")
                    case Fuda.holopower:
                        await self.game._send_message(self.player,"MESSAGE_HOLOPOWER_TOPDECK")
                    case _:
                        await self.game._send_message(self.player,"MESSAGE_FUDA_TOPDECK",{"fromFuda":fudas[int(currentFuda)]})

                await self.remove_from_fuda(currentCard,currentFuda)
                await self.cards[currentCard].unrest()
                await self.add_to_fuda(currentCard,Fuda.deck)

                await self.tell_player("Remove From List",{"card_id":currentCard})

                self.can_undo_shuffle_hand = None

            case 652: #Return to bottom of deck
                
                match currentFuda:
                    case Fuda.archive:
                        await self.game._send_message(self.player,"MESSAGE_ARCHIVE_BOTTOMDECK",{"cardName":self.cards[currentCard].number + "_NAME"})
                    case Fuda.deck:
                        await self.game._send_message(self.player,"MESSAGE_DECK_BOTTOMDECK")
                    case Fuda.holopower:
                        await self.game._send_message(self.player,"MESSAGE_HOLOPOWER_BOTTOMDECK")
                    case _:
                        await self.game._send_message(self.player,"MESSAGE_FUDA_BOTTOMDECK",{"fromFuda":fudas[int(currentFuda)]})

                await self.remove_from_fuda(currentCard,currentFuda)
                await self.cards[currentCard].unrest()
                await self.add_to_fuda(currentCard,Fuda.deck,True)

                await self.tell_player("Remove From List",{"card_id":currentCard})
                
                self.can_undo_shuffle_hand = None
            case 653: #Return to top of cheer deck
                
                match currentFuda:
                    case Fuda.archive:
                        await self.game._send_message(self.player,"MESSAGE_ARCHIVE_TOPCHEERDECK",{"cardName":self.cards[currentCard].number + "_NAME"})
                    case Fuda.cheerDeck:
                        await self.game._send_message(self.player,"MESSAGE_CHEERDECK_TOPCHEERDECK")
                    case _:
                        await self.game._send_message(self.player,"MESSAGE_FUDA_TOPCHEERDECK",{"fromFuda":fudas[int(currentFuda)]})

                await self.remove_from_fuda(currentCard,currentFuda)
                await self.cards[currentCard].unrest()
                await self.add_to_fuda(currentCard,Fuda.cheerDeck)

                await self.tell_player("Remove From List",{"card_id":currentCard})
                
            case 654: #Return to bottom of cheer deck
                
                match currentFuda:
                    case Fuda.archive:
                        await self.game._send_message(self.player,"MESSAGE_ARCHIVE_BOTTOMCHEERDECK",{"cardName":self.cards[currentCard].number + "_NAME"})
                    case Fuda.cheerDeck:
                        await self.game._send_message(self.player,"MESSAGE_CHEERDECK_BOTTOMCHEERDECK")
                    case _:
                        await self.game._send_message(self.player,"MESSAGE_FUDA_BOTTOMCHEERDECK",{"fromFuda":fudas[int(currentFuda)]})
                
                await self.remove_from_fuda(currentCard,currentFuda)
                await self.cards[currentCard].unrest()
                await self.add_to_fuda(currentCard,Fuda.cheerDeck,True)

                await self.tell_player("Remove From List",{"card_id":currentCard})

            case 655: #Archive
                if currentFuda == Fuda.holopower:
                    await self.game._send_message(self.player,"MESSAGE_HOLOPOWER_ARCHIVE",{"cardName":self.cards[currentCard].number+"_NAME"})
                else:
                    await self.game._send_message(self.player,"MESSAGE_FUDA_ARCHIVE",{"fromFuda":fudas[int(currentFuda)],"cardName":self.cards[currentCard].number+"_NAME"})
                await self.remove_from_fuda(currentCard,currentFuda)
                await self.cards[currentCard].unrest()
                await self.add_to_fuda(currentCard,Fuda.archive)

                await self.tell_player("Remove From List",{"card_id":currentCard})
                
            case 656: #Holopower

                if currentFuda == Fuda.archive:
                    await self.game._send_message(self.player,"MESSAGE_ARCHIVE_HOLOPOWER",{"cardName":self.cards[currentCard].number + "_NAME"})
                else:
                    await self.game._send_message(self.player,"MESSAGE_FUDA_HOLOPOWER",{"fromFuda":fudas[int(currentFuda)]})

                await self.remove_from_fuda(currentCard,currentFuda)
                await self.cards[currentCard].unrest()
                await self.add_to_fuda(currentCard,Fuda.holopower)

                await self.tell_player("Remove From List",{"card_id":currentCard})
            case _:
                pass


    async def popup_from_attached_command(self, command_id, data):
        currentCard = data["currentCard"]

        try:
            currentAttached = self.cards[data["currentAttached"]]
        except IndexError:
            return
        
        match command_id:
            case 603: #To Life
                actualCard = self.cards[currentCard]
                if len(self.life) < 6 and actualCard.cardType == "Cheer":
                    await self.game._send_message(self.player,"MESSAGE_ATTACHED_LIFE",{"cardName":actualCard.number + "_NAME","fromZone":await self.find_what_zone(currentAttached.id),"fromName":currentAttached.number+"_NAME"})
                    await self.remove_from_attached(currentCard,currentAttached)
                    
                    self.life.insert(0, actualCard)
                    await actualCard.trulyHide()
                    await actualCard.rest()

                    await self.tell_player("Remove From List",{"card_id":currentCard})
                    await self.tell_player("To Life",{"card_id":currentCard})
                    await self.tell_others("To Life")
            case 650: #Add to Hand
                await self.game._send_message(self.player,"MESSAGE_ATTACHED_HAND",{"cardName":actualCard.number + "_NAME","fromZone":await self.find_what_zone(currentAttached.id),"fromName":currentAttached.number+"_NAME"})
                await self.remove_from_attached(currentCard,currentAttached)
                await self.cards[currentCard].unrest()
                await self.add_to_hand(currentCard)
                await self.tell_player("Remove From List",{"card_id":currentCard})
                self.can_undo_shuffle_hand = None
                
            case 651: #Return to top of deck
                await self.game._send_message(self.player,"MESSAGE_ATTACHED_TOPDECK",{"cardName":actualCard.number + "_NAME","fromZone":await self.find_what_zone(currentAttached.id),"fromName":currentAttached.number+"_NAME"})
                
                await self.remove_from_attached(currentCard,currentAttached)
                await self.cards[currentCard].unrest()
                await self.add_to_fuda(currentCard,Fuda.deck)
                await self.tell_player("Remove From List",{"card_id":currentCard})
                self.can_undo_shuffle_hand = None
            case 652: #Return to bottom of deck
                await self.game._send_message(self.player,"MESSAGE_ATTACHED_BOTTOMDECK",{"cardName":actualCard.number + "_NAME","fromZone":await self.find_what_zone(currentAttached.id),"fromName":currentAttached.number+"_NAME"})
                
                await self.remove_from_attached(currentCard,currentAttached)
                await self.cards[currentCard].unrest()
                await self.add_to_fuda(currentCard,Fuda.deck,True)
                await self.tell_player("Remove From List",{"card_id":currentCard})
                self.can_undo_shuffle_hand = None
            case 653: #Return to top of cheer deck
                await self.game._send_message(self.player,"MESSAGE_ATTACHED_TOPCHEERDECK",{"cardName":actualCard.number + "_NAME","fromZone":await self.find_what_zone(currentAttached.id),"fromName":currentAttached.number+"_NAME"})
                
                await self.remove_from_attached(currentCard,currentAttached)
                await self.cards[currentCard].unrest()
                await self.add_to_fuda(currentCard,Fuda.cheerDeck)
                await self.tell_player("Remove From List",{"card_id":currentCard})
            case 654: #Return to bottom of cheer deck
                await self.game._send_message(self.player,"MESSAGE_ATTACHED_BOTTOMCHEERDECK",{"cardName":actualCard.number + "_NAME","fromZone":await self.find_what_zone(currentAttached.id),"fromName":currentAttached.number+"_NAME"})
                
                await self.remove_from_attached(currentCard,currentAttached)
                await self.cards[currentCard].unrest()
                await self.add_to_fuda(currentCard,Fuda.cheerDeck,True)
                await self.tell_player("Remove From List",{"card_id":currentCard})
            case 655: #Archive
                await self.game._send_message(self.player,"MESSAGE_ATTACHED_ARCHIVE",{"cardName":actualCard.number + "_NAME","fromZone":await self.find_what_zone(currentAttached.id),"fromName":currentAttached.number+"_NAME"})
                
                await self.remove_from_attached(currentCard,currentAttached)
                await self.cards[currentCard].unrest()
                await self.add_to_fuda(currentCard,Fuda.archive)
                await self.tell_player("Remove From List",{"card_id":currentCard})
            case 656: #Holopower
                await self.game._send_message(self.player,"MESSAGE_ATTACHED_HOLOPOWER",{"cardName":actualCard.number + "_NAME","fromZone":await self.find_what_zone(currentAttached.id),"fromName":currentAttached.number+"_NAME"})
                
                await self.remove_from_attached(currentCard,currentAttached)
                await self.cards[currentCard].unrest()
                await self.add_to_fuda(currentCard,Fuda.holopower)
                await self.tell_player("Remove From List",{"card_id":currentCard})
            case _:
                pass
    
    async def prompt_command(self, command_id, input, data):
        currentCard = data["currentCard"] if "currentCard" in data else None
        currentAttacking = data["currentAttacking"] if "currentAttacking" in data else None

        match command_id:
            case 10: #Add Damage
                if currentCard is not None:
                    actualCard = self.cards[currentCard]
                    await actualCard.add_damage(input)
                    await self.tell_all("Damage",{"card_id":currentCard, "amount":input})
            case 11: #Remove Damage
                if currentCard is not None:
                    actualCard = self.cards[currentCard]
                    await actualCard.add_damage(-1*input)
                    await self.tell_all("Damage",{"card_id":currentCard, "amount":-1*input})
            case 12: #Add Extra HP
                if currentCard is not None:
                    actualCard = self.cards[currentCard]
                    await actualCard.add_extra_hp(input)
                    await self.tell_all("Extra HP",{"card_id":currentCard, "amount":input})
            case 13: #Remove Extra HP
                if currentCard is not None:
                    actualCard = self.cards[currentCard]
                    await actualCard.add_extra_hp(-1*input)
                    await self.tell_all("Extra HP",{"card_id":currentCard, "amount":-1*input})
                    
            case 70: #Oshi Skill X Cost
                if currentCard is not None:
                    self.used_oshi_skill = True
                    await self.game._send_message(self.player,"MESSAGE_OSHISKILL",{"skillName":self.cards[currentCard] + "_SKILL_NAME"})
                    await self.mill(Fuda.holopower,Fuda.archive,input)
            case 71: #SP Oshi Skill X Cost
                if currentCard is not None:
                    self.used_sp_oshi_skill = True
                    await self.tell_others("Used SP Skill")
                    await self.game._send_message(self.player,"MESSAGE_OSHISKILL_SP",{"skillName":self.cards[currentCard] + "_SPSKILL_NAME"})
                    await self.mill(Fuda.holopower,Fuda.archive,input)
                    
            case 80 | 81: #Holomem Arts Damage
                if currentCard is not None and currentAttacking is not None:
                    actualCard = self.cards[currentCard]
                    opponentSide = self.game.playing[self.opponent.id]
                    actualAttacking = opponentSide.cards[currentAttacking]
                    actualAttacking.offered_damage += input
                    await opponentSide.tell_player("Offered Damage",{"card_id":currentAttacking,"amount":input})
                    await self.tell_others("Attack",{"attacker":currentCard,"attacked":currentAttacking})
                    await self.game._send_message(self.player,"MESSAGE_ARTS_DAMAGE",{"fromName":actualCard.number+"_NAME",
                                                                                "artName":actualCard.number+"_ART_"+str(command_id-80)+"_NAME",
                                                                                "toName":actualAttacking.number+"_NAME"},
                                                                                {"damage":input,"fromZone":await self.find_what_zone(currentCard),
                                                                                "toZone":await opponentSide.find_what_zone(currentAttacking)})
            
            case 201: #Draw X
                if input <= len(self.deck):
                    await self.draw(input)
                    self.can_undo_shuffle_hand = None
            case 203: #Mill X
                if input <= len(self.deck):
                    await self.mill(Fuda.deck,Fuda.archive,input)
                    self.can_undo_shuffle_hand = None
            case 297: #Look At X
                if input <= len(self.deck):
                    await self.game._send_message(self.player,"MESSAGE_DECK_LOOKATX",{},{"amount":input})
                    await self.tell_player("Look At X",{"fuda":Fuda.deck, "ids":[card.id for card in self.deck[:input]]})
                    await self.tell_others("Look At X",{"fuda":Fuda.deck,"X":input})
            
            case 397: #Look At X Cheer Deck
                if input <= len(self.cheer_deck):
                    await self.game._send_message(self.player,"MESSAGE_CHEERDECK_LOOKATX",{},{"amount":input})
                    await self.tell_player("Look At X",{"fuda":Fuda.cheerDeck, "ids":[card.id for card in self.cheer_deck[:input]]})
                    await self.tell_others("Look At X",{"fuda":Fuda.cheerDeck,"X":input})
            
            case 501: #Holopower X to Archive
                if input <= len(self.holopower):
                    await self.mill(Fuda.holopower,Fuda.archive,input)
            case _:
                pass
    
    async def zone_command(self, command_id, data):
        currentCard = data["currentCard"]
        chosenZone = data["chosenZone"]
        match command_id:
            case 5: #Move to Back
                await self.game._send_message(self.player,"MESSAGE_CARD_BACK",{"fromName":self.cards[currentCard].number + "_NAME"},{"fromZone":await self.find_what_zone(currentCard)})
                await self.move_card_to_zone(currentCard,chosenZone)
            case 7: #Baton Pass
                await self.game._send_message(self.player,"MESSAGE_CARD_BATONPASS",{"fromName":self.cards[currentCard].number+"_NAME","toName":self.cards[self.zones[chosenZone]].number+"_NAME"},
                                                                            {"fromZone":await self.find_what_zone(currentCard),"toZone":chosenZone})
                await self.switch_cards_in_zones("Center",chosenZone)
                self.used_baton_pass = True
                await self.tell_player("Baton Pass")
            case 8: #Switch to Back
                await self.game._send_message(self.player,"MESSAGE_CARD_SWITCH",{"fromName":self.cards[currentCard].number+"_NAME","toName":self.cards[self.zones[chosenZone]].number+"_NAME"},
                                                                            {"fromZone":await self.find_what_zone(currentCard),"toZone":chosenZone})
                await self.switch_cards_in_zones("Center",chosenZone)
            case 22: #Attach Revealed Support
                actualCard = self.cards[currentCard]
                attachTo = self.cards[self.zones[chosenZone]]
                await self.game._send_message(self.player,"MESSAGE_SUPPORT_ATTACH",{"attachName":actualCard.number+"_NAME","toName":attachTo.number+"_NAME"},{"toZone":chosenZone})
                self.revealed.remove(currentCard)
                await attachTo.attach(actualCard)

                await self.tell_player("Attach Card", {"attachee" : actualCard.id, "attach_to": attachTo.id})
                await self.tell_others("Attach Card", {"attachee_info" : await actualCard.to_dict(), "attach_to_info": await attachTo.to_dict()})

            case 30: #Attach Life
                actualCard = self.cards[currentCard]
                attachTo = self.cards[self.zones[chosenZone]]
                await self.game._send_message(self.player,"MESSAGE_CHEER_ATTACH",{"attachName":actualCard.number+"_NAME","toName":attachTo.number+"_NAME"},{"toZone":chosenZone})
                await attachTo.attach(actualCard)

                await self.tell_player("Attach Card", {"attachee" : actualCard.id, "attach_to": attachTo.id})
                await self.tell_others("Attach Card", {"attachee_info" : await actualCard.to_dict(), "attach_to_info": await attachTo.to_dict()})
            
            case 100: #Play
                await self.game._send_message(self.player,"MESSAGE_HOLOMEM_PLAY",{"cardName":self.cards[currentCard].number + "_NAME"})
                await self.move_card_to_zone(currentCard,chosenZone)
                await self.remove_from_hand(currentCard)
                self.cards[currentCard].bloomed_this_turn = True
                await self.tell_player("Card Played", {"card_id":currentCard})
            case 101: #Bloom
                actualCard = self.cards[currentCard]
                await self.bloom_on_zone(actualCard,chosenZone)
                await self.remove_from_hand(currentCard)
            case 103: #Play Hidden to Back
                await self.move_card_to_zone(currentCard,chosenZone,True)
                await self.remove_from_hand(currentCard,True)
            case 121: #Attach Support
                actualCard = self.cards[currentCard]
                attachTo = self.cards[self.zones[chosenZone]]
                await self.game._send_message(self.player,"MESSAGE_SUPPORT_ATTACH",{"attachName":actualCard.number+"_NAME","toName":attachTo.number+"_NAME"},{"toZone":chosenZone})
                await self.remove_from_hand(currentCard)
                await attachTo.attach(actualCard)

                await self.tell_player("Attach Card", {"attachee" : actualCard.id, "attach_to": attachTo.id})
                await self.tell_others("Attach Card", {"attachee_info" : await actualCard.to_dict(), "attach_to_info": await attachTo.to_dict()})
            
            case 300: #Attach Cheer
                actualCard = self.cards[currentCard]
                attachTo = self.cards[self.zones[chosenZone]]
                await self.game._send_message(self.player,"MESSAGE_CHEER_ATTACH",{"attachName":actualCard.number+"_NAME","toName":attachTo.number+"_NAME"},{"toZone":chosenZone})
                
                await attachTo.attach(actualCard)

                await self.tell_player("Attach Card", {"attachee" : actualCard.id, "attach_to": attachTo.id})
                await self.tell_others("Attach Card", {"attachee_info" : await actualCard.to_dict(), "attach_to_info": await attachTo.to_dict()})
            
            case 600: #Play From Deck
                await self.game._send_message(self.player,"MESSAGE_DECK_HOLOMEM_PLAY",{"cardName":self.cards[currentCard].number + "_NAME"})
                await self.remove_from_fuda(currentCard,Fuda.deck)
                await self.move_card_to_zone(currentCard,chosenZone)
                self.cards[currentCard].bloomed_this_turn = True
                self.can_undo_shuffle_hand = None
            case 601,604: #Bloom From Deck
                await self.remove_from_fuda(currentCard,Fuda.deck)
                actualCard = self.cards[currentCard]
                await self.bloom_on_zone(actualCard,chosenZone)
                self.can_undo_shuffle_hand = None
            case 602: #Attach Cheer From Deck
                await self.remove_from_fuda(currentCard,Fuda.cheerDeck)
                actualCard = self.cards[currentCard]
                attachTo = self.cards[self.zones[chosenZone]]
                await self.game._send_message(self.player,"MESSAGE_CHEERDECK_CHEER_ATTACH",{"attachName":actualCard.number+"_NAME","toName":attachTo.number+"_NAME"},{"toZone":chosenZone})
                await attachTo.attach(actualCard)
                await self.tell_player("Attach Card", {"attachee" : actualCard.id, "attach_to": attachTo.id})
                await self.tell_others("Attach Card", {"attachee_info" : await actualCard.to_dict(), "attach_to_info": await attachTo.to_dict()})
            case 610: #Play From Archive
                await self.game._send_message(self.player,"MESSAGE_ARCHIVE_HOLOMEM_PLAY",{"cardName":self.cards[currentCard].number + "_NAME"})
                await self.remove_from_fuda(currentCard,Fuda.archive)
                await self.move_card_to_zone(currentCard,chosenZone)
                self.cards[currentCard].bloomed_this_turn = True
            case 611,614: #Bloom From Archive
                await self.remove_from_fuda(currentCard,Fuda.archive)
                actualCard = self.cards[currentCard]
                await self.bloom_on_zone(actualCard,chosenZone)
            case 612: #Attach Cheer From Archive
                await self.remove_from_fuda(currentCard,Fuda.archive)
                actualCard = self.cards[currentCard]
                attachTo = self.cards[self.zones[chosenZone]]
                await self.game._send_message(self.player,"MESSAGE_ARCHIVE_CHEER_ATTACH",{"attachName":actualCard.number+"_NAME","toName":attachTo.number+"_NAME"},{"toZone":chosenZone})
                await attachTo.attach(actualCard)
                await self.tell_player("Attach Card", {"attachee" : actualCard.id, "attach_to": attachTo.id})
                await self.tell_others("Attach Card", {"attachee_info" : await actualCard.to_dict(), "attach_to_info": await attachTo.to_dict()})
                
            case 622: #Attach Cheer From Attach
                try:
                    currentAttached = self.cards[data["currentAttached"]]
                    await self.remove_from_attached(currentCard,currentAttached)
                    actualCard = self.cards[currentCard]
                    attachTo = self.cards[self.zones[chosenZone]]
                    await self.game._send_message(self.player,"MESSAGE_ATTACHED_CHEER_ATTACH",{"attachName":actualCard.number+"_NAME","toName":attachTo.number+"_NAME","fromName":currentAttached.number + "_NAME"},
                                                                                        {"toZone":chosenZone,"fromZone":await self.find_what_zone(currentAttached.id)})
                    await attachTo.attach(actualCard)
                    await self.tell_player("Attach Card", {"attachee" : actualCard.id, "attach_to": attachTo.id})
                    await self.tell_others("Attach Card", {"attachee_info" : await actualCard.to_dict(), "attach_to_info": await attachTo.to_dict()})
                except IndexError:
                    return
            case _:
                pass
    
    async def call_command(self, player_id, command, data):
        if player_id == self.player.id:
            match command:
                case "Yes Mulligan":
                    if self.in_mulligans:
                        await self.yes_mulligan()
                case "No Mulligan":
                    if self.in_mulligans:
                        await self.no_mulligan()
                case "Ready":
                    if self.preliminary_phase and not self.in_mulligans and self.preliminary_holomem_in_center:
                        await self.game._ready(self.player.id)
                case "Popup Command":
                    if "command_id" in data and self.can_do_things:
                        await self.popup_command(data["command_id"], data)
                case "Popup From Fuda Command":
                    if "currentCard" in data and "command_id" in data and "currentFuda" in data and self.can_do_things:
                        await self.popup_from_fuda_command(data["command_id"], data)
                case "Popup From Attached Command":
                    if "currentCard" in data and "command_id" in data and "currentAttached" in data and self.can_do_things:
                        await self.popup_from_attached_command(data["command_id"], data)
                case "Prompt Command":
                    if "input" in data and "command_id" in data and self.can_do_things:
                        await self.prompt_command(data["command_id"], int(data["input"]), data)
                case "Zone Command":
                    if "currentCard" in data and "chosenZone" in data and "command_id" in data and self.can_do_things:
                        await self.zone_command(data["command_id"], data)
                case "Roll Die":
                    rolled = randrange(1,7)
                    await self.tell_all("Roll Die",{"result":rolled})
                    await self.game._send_message(self.player,"MESSAGE_DIERESULT",{},{"amount":rolled})
                case "Stop Look At":
                    await self.tell_others("Stop Look At")
                case "Accept Damage":
                    if "card_id" in data:
                        actualCard = self.cards[data["card_id"]]
                        await actualCard.add_damage(actualCard.offered_damage)
                        await self.tell_player("Accepted Damage",{"card_id":data["card_id"]})
                        await self.tell_all("Damage",{"card_id":data["card_id"], "amount":actualCard.offered_damage})
                        actualCard.offered_damage = 0
                case "Click Notification":
                    if "player_id" in data and "card_id" in data:
                        if data["player_id"] == player_id:
                            await self.tell_others("Click Notification",{"card_id":data["card_id"]})
                        else:
                            await self.game.playing[self.opponent.id].tell_player("Click Notification",{"card_id":data["card_id"]})
                case _:
                    pass
    
    async def tell_player(self, command, data=None):
        await self.player.tell("Your Side", command, data)
    
    async def tell_others(self, command, data=None):
        await self.opponent.tell("Opponent Side", command, data)

        await self.game.tell_spectators(self, command, data)
    
    async def tell_all(self, command, data=None):
        await self.tell_player(command, data)
        await self.tell_others(command, data)
    
    async def to_dict(self):
        result = {"deck":len(self.deck),"cheerDeck":len(self.cheer_deck),"holopower":len(self.holopower),"life":len(self.life),"hand":len(self.hand),"archive":[],"zones":{},"revealed":[]}
        for archived in self.archive:
            result["archive"].append(await archived.to_dict())
        for zone in self.zones:
            if self.zones[zone] != -1:
                if self.preliminary_phase:
                    result["zones"][zone] = None
                else:
                    result["zones"][zone] = await self.cards[self.zones[zone]].to_dict()
        if self.preliminary_phase:
            result["oshi"] = None
        else:
            result["oshi"] = await self.oshi.to_dict()
        
        for revealed in self.revealed:
            result["revealed"].append(await revealed.to_dict())
        
        result["playing"] = None if self.playing is None else await self.playing.to_dict()

        return result


games = {}
class Game:
    def __init__(self, player1, player1deck, player2, player2deck, settings = None):
        self.id = ''.join(sample(random_characters, 10))
        while self.id in games:
            self.id = ''.join(sample(random_characters, 10))
        games[self.id] = self
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
    
    async def close_game(self):
        for player in self.players.values():
            await player.tell("Game","Close")
            player.game = None
        
        del games[self.id]        
    
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
    
    async def to_dict(self):
        return {"step":self.step,"firstTurn":self.firstTurn,"players":{player.id: {"name":player.name, "side":await self.playing[player.id].to_dict()} for player in self.players.values()}}

lobbies = {}
class Lobby:
    def __init__(self, host, settings = None):
        self.id = ''.join(sample(random_characters, 10))
        while self.id in lobbies:
            self.id = ''.join(sample(random_characters, 10))
        lobbies[self.id] = self
        self.host = host
        host.lobby = self
        self.host_deck = None
        self.host_ready = False
        self.chosen = None
        self.chosen_deck = None
        self.chosen_ready = False
        self.waiting = []
        self.settings = {} if settings is None else settings
        self.public = self.settings["public"] if "public" in self.settings else True
        self.banlist = self.settings["banlist"] if "banlist" in self.settings else dict(current_banlist)
        self.allow_spectators = self.settings["spectators"] if "spectators" in self.settings else False
        if self.banlist == {}:
            self.banlistCode = Banlist.none
        elif self.banlist == current_banlist:
            self.banlistCode = Banlist.current
        elif self.banlist == (current_banlist | unreleased):
            self.banlistCode = Banlist.unreleased
        else:
            self.banlistCode = Banlist.custom
        
    async def add_player(self, player_id):
        player = players[player_id]
        if player not in self.waiting and player != self.host:
            self.waiting.append(player)
            player.lobby = self
            await player.tell("Lobby","Join",{"id":self.id,"hostName":self.host.name})
            await self.update_all("Player Joined")
    
    async def remove_player(self, player_id):
        player = players[player_id]
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

    async def close_lobby(self):
        await self.host.tell("Lobby","Close")
        for player in self.waiting:
            await player.tell("Lobby","Close")
        
        self.host.lobby = None
        for player in self.waiting:
            player.lobby = None
        self.waiting = []
        self.chosen = None
        del lobbies[self.id]
    
    async def update_all(self,reason="Update"):
        current_state = {"waiting":{player.id:player.name for player in self.waiting},"chosen":None if self.chosen is None else self.chosen.id,"host_ready":self.host_ready,"chosen_ready":self.chosen_ready}
        await self.host.tell("Lobby","Update",{"reason":reason,"state":current_state,"lobby_id":self.id,"you_are_chosen":False})
        for player in self.waiting:
            await player.tell("Lobby","Update",{"reason":reason,"state":current_state,"lobby_id":self.id,"you_are_chosen":(False if self.chosen is None else self.chosen.id == player.id)})
    
    async def call_command(self, player_id,command, data):
        match command:
            case "Choose Opponent":
                if "chosen" in data and data["chosen"] in players and players[data["chosen"]] in self.waiting:
                    self.chosen = players[data["chosen"]]
                    await self.update_all("Player Chosen")
            case "Ready":
                if "deck" in data:
                    is_host = player_id == self.host.id and self.host_deck is None
                    is_chosen = self.chosen is not None and player_id == self.chosen.id and self.chosen_deck is None

                    if is_host or is_chosen:
                        deck, deck_legality = check_legal(data["deck"], self.banlist)
                        await players[player_id].tell("Lobby","Deck Legality",deck_legality)

                        if deck_legality["legal"]:
                            if is_host:
                                self.host_deck = deck
                                self.host_ready = True
                                await self.update_all("Host Readied")
                            elif is_chosen:
                                self.chosen_deck = deck
                                self.chosen_ready = True
                                await self.update_all("Chosen Readied")

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


app = FastAPI()
app.mount("/game", StaticFiles(directory="Holodelta_web"), name="game")
app.mount("/cards", StaticFiles(directory="cards"), name="cards")



@app.get("/")
def index():
    return RedirectResponse(url="/game/index.html")

@app.get("/card/{card_id}")
def call_card_info(card_id: str):
    return card_info(card_id)

@app.get("/cardList")
def get_cards():
    return card_data

@app.get("/check")
def check_connection():
    return {"Success"}

@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await manager.connect(websocket)
    try:
        player = Player(websocket)
        await player.tell("Server","Player Info",{"id":player.id, "name":player.name,"current":current_banlist,"unreleased":unreleased})
        while True:
            json_data = await websocket.receive_bytes()
            message = json.loads(str(json_data,'ascii'))
            if "supertype" in message and "command" in message and player.id in players:
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
    except WebSocketDisconnect:
        await manager.websocket_to_player[websocket].remove()
        manager.disconnect(websocket)

async def call_command(player_id,command, data):
    player = players[player_id]
    match command:
        case "Create Lobby": 
            if player.lobby is None and player.game is None:
                settings = data["settings"] if "settings" in data else {}
                lobby = Lobby(players[player_id], settings)
                await player.tell("Server","Created Lobby",{"id":lobby.id,"host_name":lobby.host.name})
            else:
                await player.tell("Server","Create Lobby Failed")
        case "Join Lobby":
            if "lobby" in data and data["lobby"] in lobbies and player.lobby is None and player.game is None:
                await lobbies[data["lobby"]].add_player(player_id)
            else:
                await player.tell("Server","Join Lobby Failed")
        case "Find Lobbies":
            #This will have to update to take filtering into account

            found = [{"id":lob.id, "hostName": lob.host.name, "waiting": len(lob.waiting), "banlist":int(lob.banlistCode)} for lob in lobbies.values() if lob.public]

            await player.tell("Server","Found Lobbies",{"lobbies":found})
        case "Find Games":
            #This will have to update to take filtering into account

            found = [{"id":game.id, "players":[p.name for p in game.players.values()] } for game in games.values() if game.allow_spectators]

            await player.tell("Server","Found Games",{"games":found})
        
        case "Spectate":
            if "game" in data and data["game"] in games and player.lobby is None and player.game is None:
                game_to_spectate = games[data["game"]]
                game_to_spectate.spectating.append(player)
                player.game = game_to_spectate
                await player.tell("Server","Spectate",{"game_state":await game_to_spectate.to_dict()})
        
        case "Name Change":
            if "new_name" in data and isinstance(data["new_name"],str):
                player.name = data["new_name"]

        case _:
            pass

