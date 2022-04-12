from enum import IntEnum


class ActionType(IntEnum):
    hint_color = 1
    hint_rank = 2
    play = 3
    discard = 4


class Action:
    def __init__(self, action_type, index, pnr):
        self.type = action_type
        self.index = index
        self.pnr = pnr


class Player:
    def __init__(self, name, pnr):
        self.name = name
        self.pnr = pnr

    def __hash__(self):
        return hash(self.name) + self.pnr

    def get_action(self):
        pass

    def inform(self, action):
        pass
