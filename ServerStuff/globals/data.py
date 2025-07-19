import json
from random import sample
from string import ascii_lowercase, digits

data = {}

def initialize():
    random_characters = ascii_lowercase+digits
    data["random_characters"] = random_characters
    with open('data_source/banlists/current.json', 'r') as file:
        data["current_banlist"] = json.load(file)
    with open('data_source/banlists/en_current.json', 'r') as file:
        data["en_current_banlist"] = json.load(file)
    with open('data_source/banlists/unreleased.json', 'r') as file:
        data["unreleased"] = json.load(file)
    with open('data_source/cardData.json', 'r') as file:
        data["card_data"] = json.load(file)
    data["bloom_levels"] = {-1:"LEVEL_SPOT",0:"LEVEL_DEBUT",1:"LEVEL_1",2:"LEVEL_2"}
    data["fudas"] = ["DECK","CHEERDECK","ARCHIVE","HOLOPOWER"]
    data["identifier"] = ''.join(sample(random_characters, 10))

def get_data(key: str):
    return data.get(key)