from enum import IntEnum
from itertools import product
from random import seed, shuffle


class Color(IntEnum):
    blue = 1
    green = 2
    red = 3
    white = 4
    yellow = 5


class Card:
    def __init__(self, color, rank, owner=None, game=None):
        self._color = color
        self._rank = rank
        self._colors = set(Color)
        self._ranks = set(range(1, 6))
        self.owner = owner
        self.game = game

    def __str__(self):
        return "<{} {}>".format(self._color.name, self._rank)

    def __eq__(self, other):
        return self._color == other._color and self._rank == other._rank

    def __hash__(self):
        return self._color * 59 + self._rank

    def get_color(self, player=None):
        """
        Return the true color if not owner, otherwise the set of all possible colors
        """
        return self._colors if player == self.owner else self.color

    def get_rank(self, player=None):
        """
        Return the true rank if not owner, otherwise the set of all possible ranks
        """
        return self._ranks if player == self.owner else self.rank

    def hint_color(self, color):
        """Update the set of all possible colors"""
        if color == self._color:
            self._colors = {self._color}
        else:
            self._colors.discard(color)

    def hint_rank(self, rank):
        """Update the set of all possible ranks"""
        if rank == self._rank:
            self._ranks = {self._rank}
        else:
            self._ranks.discard(rank)

    @property
    def possible(self):
        return [Card(color, rank) for color, rank in product(self._colors, self._ranks)]

    def show_knowledge(self):
        res = ""
        for color in Color:
            if color in self._colors:
                res += " " + color.name
            else:
                res += " " * (len(color.name) + 1)
        for rank in range(1, 6):
            if rank in self._ranks:
                res += " " + str(rank)
            else:
                res += "  "
        return res


class Deck:
    def __init__(self, init=None):
        self._count = {}
        self._deck = []
        for (color, (rank, count)) in product(Color, enumerate([3, 2, 2, 2, 1])):
            self._deck.extend([Card(color, rank + 1) for _ in range(count)])
            self._count[Card(color, rank + 1)] = count
        if init:
            seed(init)
        shuffle(self._deck)
        self.count = self._count.get

    def pop(self):
        """Deal a card from the deck, update the counter"""
        try:
            card = self._deck.pop()
            self._count[card] -= 1
            return card
        except IndexError:
            return None

    @property
    def isempty(self):
        return self._deck == []


class Hand:
    def __init__(self, deck, onwer=None, num=5):
        self._deck = deck
        self.cards = []
        self.onwer = onwer
        for i in range(num):
            self.get()

    def __str__(self):
        return str([str(card) for card in self.cards])

    def __getitem__(self, key):
        return self.cards[key]

    def show_knowledge(self, prefix=""):
        for i, card in enumerate(self.cards):
            print(prefix, i + 1, card.show_knowledge())

    def get(self):
        self.cards.append(self._deck.pop())
        self.cards[-1].onwer = self.onwer

    def hint_color(self, color):
        for card in self.cards:
            card.hint_color(color)

    def hint_rank(self, rank):
        for card in self.cards:
            card.hint_rank(rank)

    def remove(self, index):
        card = self.cards[index - 1]
        del self.cards[index - 1]
        self.get()
        return card


class Board:
    def __init__(self):
        self._count = {color: 0 for color in Color}

    def __str__(self):
        return " ".join(
            ["Board:\n"]
            + ["{}: {} |".format(col.name, self._count[col]) for col in sorted(Color)]
        )

    def play(self, card):
        """Try to play a card. Return True for successful play, o.w. False"""
        if self._count[card._color] == card._rank - 1:
            self._count[card._color] += 1
            return True
        else:
            return False

    @property
    def score(self):
        return sum(self._count.values())


class Trash:
    def __init__(self):
        self._count = {}

    def __str__(self):
        res = "Trash:\n"
        for color in Color:
            res += ("  " + color.name + ":").ljust(10, " ")
            for rank in range(1, 6):
                for i in range(self.count(Card(color, rank))):
                    res += str(rank) + " "
            res += "\n"
        return res

    def add(self, card):
        self._count[card] = self.count(card) + 1

    def count(self, card):
        return self._count.get(card, 0)
