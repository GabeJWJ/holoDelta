import json
import os
from random import sample
from string import ascii_lowercase, digits

data = {}

def initialize():
    # 獲取當前腳本所在目錄
    current_dir = os.path.dirname(os.path.abspath(__file__))
    server_dir = os.path.dirname(current_dir)  # ServerStuff 目錄
    
    random_characters = ascii_lowercase+digits
    data["random_characters"] = random_characters
    
    # 使用絕對路徑
    with open(os.path.join(server_dir, 'data_source/banlists/current.json'), 'r') as file:
        data["current_banlist"] = json.load(file)
    with open(os.path.join(server_dir, 'data_source/banlists/en_current.json'), 'r') as file:
        data["en_current_banlist"] = json.load(file)
    with open(os.path.join(server_dir, 'data_source/banlists/unreleased.json'), 'r') as file:
        data["unreleased"] = json.load(file)
    with open(os.path.join(server_dir, 'data_source/cardData.json'), 'r') as file:
        data["card_data"] = json.load(file)
    with open(os.path.join(server_dir, 'data_source/client_version.txt'),'r') as file:
        data["client_version"] = file.read()
    with open(os.path.join(server_dir, 'data_source/card_version.txt'),'r') as file:
        data["card_version"] = file.read()
    data["bloom_levels"] = {-1:"LEVEL_SPOT",0:"LEVEL_DEBUT",1:"LEVEL_1",2:"LEVEL_2"}
    data["fudas"] = ["DECK","CHEERDECK","ARCHIVE","HOLOPOWER"]
    data["identifier"] = ''.join(sample(random_characters, 10))

def get_data(key: str):
    return data.get(key)