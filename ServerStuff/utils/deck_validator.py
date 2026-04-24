from utils.card_utils import card_info, find_in_list
from globals.data import get_data

def check_legal(deck, banlist = None, only_en = False):
    if banlist is None:
        banlist = get_data("current_banlist")

    result = {"legal":True,"reasons":[]}
    real_deck = {}

    if "oshi" in deck:
        oshi_info = deck["oshi"]
        if type(oshi_info) is list and len(oshi_info) == 2 and type(oshi_info[0]) is str and type(oshi_info[1]) is int:
            oshi_number = oshi_info[0]
            oshi_card = card_info(card_id=oshi_number)
            oshi_art = oshi_info[1]
            if "cardType" in oshi_card:
                if oshi_card["cardType"] == "Oshi":
                    if str(oshi_art) in oshi_card["cardArt"]:
                        if find_in_list(banlist, oshi_number) is None:
                            if only_en and not check_if_card_is_en(oshi_number, oshi_art):
                                result["legal"] = False
                                result["reasons"].append(["DECKERROR_ONLYEN",oshi_number])
                        else:
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
                main_card = card_info(card_id=main_number)
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
                                    banned_code = find_in_list(banlist, main_number)
                                    if banned_code is None:
                                        if only_en and not check_if_card_is_en(main_number, main_art):
                                            result["legal"] = False
                                            result["reasons"].append(["DECKERROR_ONLYEN",main_number])
                                    else:
                                        if banlist[banned_code] == 0:
                                            result["legal"] = False
                                            result["reasons"].append(["DECKERROR_BANNED",main_number])
                                        elif banlist[banned_code] < main_count:
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
                cheer_card = card_info(card_id=cheer_number)
                cheer_count = cheer_row[1]
                cheer_art = cheer_row[2]

                total_cheer += cheer_count

                if "cardType" in cheer_card:
                    if cheer_card["cardType"] == "Cheer":
                        if cheer_card["cardLimit"] == -1 or cheer_count <= cheer_card["cardLimit"]:
                            if cheer_count > 0:
                                if str(cheer_art) in cheer_card["cardArt"]:
                                    banned_code = find_in_list(banlist, cheer_number)
                                    if banned_code is None:
                                        if only_en and not check_if_card_is_en(cheer_number, cheer_art):
                                            result["legal"] = False
                                            result["reasons"].append(["DECKERROR_ONLYEN",cheer_number])
                                    else:
                                        if banlist[banned_code] == 0:
                                            result["legal"] = False
                                            result["reasons"].append(["DECKERROR_BANNED",cheer_number])
                                        elif banlist[banned_code] < cheer_count:
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

def check_if_card_is_en(cardNumber, artNum):
    card_data = get_data("card_data")
    return cardNumber in card_data and str(artNum) in card_data[cardNumber]["cardArt"] and \
		"en" in card_data[cardNumber]["cardArt"][str(artNum)] and not card_data[cardNumber]["cardArt"][str(artNum)]["en"]["proxy"]