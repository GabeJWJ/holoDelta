from globals.data import get_data

def matches(fromList, toCheck):
    if fromList == toCheck:
        return True
    else:
        matched = True
        for i in range(len(fromList)):
            if fromList[i] != "*" and (i >= len(toCheck) or fromList[i] != toCheck[i]):
                matched = False
        return matched
    
def find_in_list(listToSearch, toCheck):
    for possible in listToSearch:
        if matches(possible,toCheck):
            return possible
    return None

def card_info(card_id: str,card_data: object = None):
    card_data_to_check = card_data
    if (card_data is None) or (not isinstance(card_data, dict)):
        card_data_to_check = get_data("card_data")
    return card_data_to_check[card_id] if card_id in card_data_to_check else {}

