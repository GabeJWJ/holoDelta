from enum import IntEnum

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