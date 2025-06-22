from classes.enums import Fuda, BloomCode
from globals.data import get_data
from random import shuffle, randrange
from classes.card import Card



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
        fudas = get_data("fudas")
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
        
        #if await self.find_what_zone(card_id):
            #await self.remove_old_card(card_id)
        
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
        bloom_levels = get_data("bloom_levels")
        bloomee = self.cards[self.zones[zone_to_bloom]]
        await card_to_bloom.bloom(bloomee)
        self.zones[zone_to_bloom] = card_to_bloom.id

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
            case 26: #Send Revealed Card to Holopower
                if currentCard is not None:
                    await self.game._send_message(self.player,"MESSAGE_REVEALED_HOLOPOWER",{"cardName":self.cards[currentCard].number + "_NAME"})
                    await self.remove_old_card(currentCard,True)
                    await self.add_to_fuda(currentCard, Fuda.holopower)
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
                    await self.game._send_message(self.player,"MESSAGE_OSHISKILL",{"skillName":self.cards[currentCard].number + "_SKILL_NAME"})
                    await self.mill(Fuda.holopower,Fuda.archive,self.cards[currentCard].skill_cost)
            case 71: #SP Oshi Skill
                if currentCard is not None and self.cards[currentCard].spskill_cost >= 0:
                    self.used_sp_oshi_skill = True
                    await self.tell_others("Used SP Skill")
                    await self.game._send_message(self.player,"MESSAGE_OSHISKILL_SP",{"skillName":self.cards[currentCard].number + "_SPSKILL_NAME"})
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
            
            case 410: #Archive Hand
                await self.game._send_message(self.player,"MESSAGE_ARCHIVE_HAND_ALL")

                for potentialCard in self.hand.copy():
                    await self.add_to_fuda(potentialCard.id,Fuda.archive)
                    await self.remove_from_hand(potentialCard.id)
            
            case 500: #Holopower to Archive
                await self.mill(Fuda.holopower,Fuda.archive)
            case 505: #Reveal Top Card From Holopower
                actualCard = self.holopower[0]
                currentCard = actualCard.id
                await self.game._send_message(self.player,"MESSAGE_HOLOPOWER_REVEAL",{"cardName":actualCard.number + "_NAME"})
                await self.remove_from_fuda(currentCard,Fuda.holopower)

                self.revealed.append(currentCard)
                await self.tell_player("Reveal",{"card_id":currentCard})
                await self.tell_others("Reveal",{"card":await actualCard.to_dict()})
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
        fudas= get_data("fudas")
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
        actualCard = self.cards[currentCard]

        try:
            currentAttached = self.cards[data["currentAttached"]]
        except IndexError:
            return
        
        match command_id:
            case 603: #To Life
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
                await actualCard.unrest()
                await self.add_to_hand(currentCard)
                await self.tell_player("Remove From List",{"card_id":currentCard})
                self.can_undo_shuffle_hand = None
                
            case 651: #Return to top of deck
                await self.game._send_message(self.player,"MESSAGE_ATTACHED_TOPDECK",{"cardName":actualCard.number + "_NAME","fromZone":await self.find_what_zone(currentAttached.id),"fromName":currentAttached.number+"_NAME"})
                
                await self.remove_from_attached(currentCard,currentAttached)
                await actualCard.unrest()
                await self.add_to_fuda(currentCard,Fuda.deck)
                await self.tell_player("Remove From List",{"card_id":currentCard})
                self.can_undo_shuffle_hand = None
            case 652: #Return to bottom of deck
                await self.game._send_message(self.player,"MESSAGE_ATTACHED_BOTTOMDECK",{"cardName":actualCard.number + "_NAME","fromZone":await self.find_what_zone(currentAttached.id),"fromName":currentAttached.number+"_NAME"})
                
                await self.remove_from_attached(currentCard,currentAttached)
                await actualCard.unrest()
                await self.add_to_fuda(currentCard,Fuda.deck,True)
                await self.tell_player("Remove From List",{"card_id":currentCard})
                self.can_undo_shuffle_hand = None
            case 653: #Return to top of cheer deck
                await self.game._send_message(self.player,"MESSAGE_ATTACHED_TOPCHEERDECK",{"cardName":actualCard.number + "_NAME","fromZone":await self.find_what_zone(currentAttached.id),"fromName":currentAttached.number+"_NAME"})
                
                await self.remove_from_attached(currentCard,currentAttached)
                await actualCard.unrest()
                await self.add_to_fuda(currentCard,Fuda.cheerDeck)
                await self.tell_player("Remove From List",{"card_id":currentCard})
            case 654: #Return to bottom of cheer deck
                await self.game._send_message(self.player,"MESSAGE_ATTACHED_BOTTOMCHEERDECK",{"cardName":actualCard.number + "_NAME","fromZone":await self.find_what_zone(currentAttached.id),"fromName":currentAttached.number+"_NAME"})
                
                await self.remove_from_attached(currentCard,currentAttached)
                await actualCard.unrest()
                await self.add_to_fuda(currentCard,Fuda.cheerDeck,True)
                await self.tell_player("Remove From List",{"card_id":currentCard})
            case 655: #Archive
                await self.game._send_message(self.player,"MESSAGE_ATTACHED_ARCHIVE",{"cardName":actualCard.number + "_NAME","fromZone":await self.find_what_zone(currentAttached.id),"fromName":currentAttached.number+"_NAME"})
                
                await self.remove_from_attached(currentCard,currentAttached)
                await actualCard.unrest()
                await self.add_to_fuda(currentCard,Fuda.archive)
                await self.tell_player("Remove From List",{"card_id":currentCard})
            case 656: #Holopower
                await self.game._send_message(self.player,"MESSAGE_ATTACHED_HOLOPOWER",{"cardName":actualCard.number + "_NAME","fromZone":await self.find_what_zone(currentAttached.id),"fromName":currentAttached.number+"_NAME"})
                
                await self.remove_from_attached(currentCard,currentAttached)
                await actualCard.unrest()
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
                    await self.game._send_message(self.player,"MESSAGE_OSHISKILL",{"skillName":self.cards[currentCard].number + "_SKILL_NAME"})
                    await self.mill(Fuda.holopower,Fuda.archive,input)
            case 71: #SP Oshi Skill X Cost
                if currentCard is not None:
                    self.used_sp_oshi_skill = True
                    await self.tell_others("Used SP Skill")
                    await self.game._send_message(self.player,"MESSAGE_OSHISKILL_SP",{"skillName":self.cards[currentCard].number + "_SPSKILL_NAME"})
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
            case 601 | 604: #Bloom From Deck
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
            case 611 | 614: #Bloom From Archive
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
                case "Reject Damage":
                    if "card_id" in data:
                        actualCard = self.cards[data["card_id"]]
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
            result["revealed"].append(await self.cards[revealed].to_dict())
        
        result["playing"] = None if self.playing is None else await self.cards[self.playing].to_dict()

        return result