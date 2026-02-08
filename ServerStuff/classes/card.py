from utils.card_utils import card_info
from classes.enums import BloomCode

class Card:
    def __init__(self, number, art_index, id):
        self.number = number
        self.art_index = art_index
        self.id = id
        self.tags = []
        self.extraNames = []
        self.attached = []
        self.onTopOf = []
        self.attachedTo = id
        self.rested = False
        self.faceDown = False
        self.trulyHidden = False
        self.onstage = False

        self.error = False

        init_info = card_info(card_id=number)
        try:
            self.cardType = init_info["cardType"]

            if "tags" in init_info:
                self.tags + init_info["tags"]
            if "extraNames" in init_info:
                self.extraNames + init_info["extraNames"]
            match self.cardType:
                case "Oshi":
                    self.life = init_info["life"]
                    self.color = init_info["color"] if "color" in init_info else []
                    self.name = init_info["name"] if "name" in init_info else []
                    self.skill_cost = 0
                    self.spskill_cost = 0
                    for skill in init_info["skills"]:
                        if bool(skill["stageSkill"]):
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
                    self.default_baton_pass_cost = init_info["batonPassCost"]
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
    
    async def add_extra_baton_pass_cost(self,amount):
        self.baton_pass_cost += amount
        if self.baton_pass_cost < 0:
            self.baton_pass_cost = 0
        if self.baton_pass_cost > 99:
            self.baton_pass_cost = 99

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
        self.onTopOf.extend(other_card.onTopOf)
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
                result["default_baton_pass_cost"] = self.default_baton_pass_cost
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