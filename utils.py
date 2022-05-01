from copy import deepcopy
from enum import IntEnum
import importlib
from itertools import product
import pickle
from random import seed, shuffle

debugging = True


card_count = {1: 3, 2: 2, 3: 2, 4: 2, 5: 1}


def _print(*args, **kwargs):
    if debugging:
        print(*args, **kwargs)


class Color(IntEnum):
    blue = 1
    green = 2
    red = 3
    white = 4
    yellow = 5


class Rank(IntEnum):
    one = 1
    two = 2
    three = 3
    four = 4
    five = 5


class Card:
    def __init__(self, color, rank, owner=None, game=None):
        self._color = color if isinstance(color, Color) else Color(color)
        self._rank = rank if isinstance(rank, Rank) else Rank(rank)
        self._colors = set(Color)
        self._ranks = set(Rank)
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
        return self._colors if player == self.owner else self._color

    def get_rank(self, player=None):
        """
        Return the true rank if not owner, otherwise the set of all possible ranks
        """
        return self._ranks if player == self.owner else self._rank

    def hint_color(self, color):
        """Update the set of all possible colors, return True iff the card is hinted"""
        if color == self._color:
            updated = self._colors != {self._color}
            self._colors = {self._color}
            return True
            return updated
        else:
            self._colors.discard(color)
            return False

    def hint_rank(self, rank):
        """Update the set of all possible ranks, return True iff the card is hinted"""
        if rank == self._rank:
            updated = self._ranks != {self._rank}
            self._ranks = {self._rank}
            return True
            return updated
        else:
            self._ranks.discard(rank)
            return False

    @property
    def possible(self):
        """All possibility of the card; no card counting"""
        return [Card(color, rank) for color, rank in product(self._colors, self._ranks)]

    def _check_game(self):
        """Ensure the card is linked to a game object"""
        if self.game is None:
            _print("game is not set for card: {}".format(str(self)))
            return False
        return True

    @property
    def playable(self):
        """Return true iff the card is definitely playable"""
        if self._check_game():
            return all(self.game.board.playable(card) for card in self.possible)
        return False

    @property
    def playable_possibly(self):
        """Return true iff the card is not definitely unplayable"""
        if self._check_game():
            return any(self.game.board.playable(card) for card in self.possible)
        return False

    @property
    def useless(self):
        """Return true iff the card is useless; no card counting"""
        if self._check_game():

            def isuseless(card):
                if self.game.board[card._color] > card._rank:
                    return True
                if self.game.board.playable(card):
                    return False
                return all(
                    self.game.trash.hasall(Card(card._color, rank))
                    for rank in range(self.game.board[card._color] + 1, card._rank)
                )

            return all(isuseless(card) for card in self.possible)

        return False

    def show_knowledge(self):
        """Visual knowledge of the card in human readable form"""
        res = ""
        for color in Color:
            if color in self._colors:
                res += " " + color.name
            else:
                res += " " * (len(color.name) + 1)
        for rank in Rank:
            if rank in self._ranks:
                res += " " + str(rank.value)
            else:
                res += "  "
        return res


class Deck:
    def __init__(self, game=None, init=None):
        self._deck = []
        for (color, (rank, count)) in product(Color, card_count.items()):
            self._deck.extend([Card(color, rank, game=game) for _ in range(count)])
        if isinstance(init, int):
            seed(init)
        if init != "noshuffle":
            shuffle(self._deck)

    def pop(self):
        """Deal a card from the deck, update the counter"""
        try:
            return self._deck.pop()
        except IndexError:
            return None

    @property
    def isempty(self):
        return self._deck == []


class Hand:
    def __init__(self, deck, owner=None, num=5):
        self._deck = deck
        self.cards = []
        self.owner = owner
        self.last_hinted = set()  # last hinted cards
        for i in range(num):
            self.get()

    def __str__(self):
        return str([str(card) for card in self.cards])

    def __getitem__(self, key):
        assert 1 <= key and key <= len(self), str(key)
        return self.cards[key - 1]

    def __len__(self):
        return len(self.cards)

    def show_knowledge(self, prefix=""):
        """Visual knowledge of the hand in human readable form"""
        for i, card in enumerate(self.cards):
            print(prefix, i + 1, card.show_knowledge())

    def get(self):
        """Deal a card from teh deck and append to the right"""
        card = self._deck.pop()
        if card is not None:
            card.owner = self.owner
            self.cards.append(card)

    def hint_color(self, color):
        """Update all cards in hand with new hint"""
        self.last_hinted = set()
        for i, card in enumerate(self.cards):
            if card.hint_color(color):
                self.last_hinted.add(i + 1)

    def hint_rank(self, rank):
        """Update all cards in hand with new hint"""
        self.last_hinted = set()
        for i, card in enumerate(self.cards):
            if card.hint_rank(rank):
                self.last_hinted.add(i + 1)

    def gain_hint_color(self, color):
        """Hypothesized number of possibilities eliminated by hinting a color"""
        copied = deepcopy(self.cards)
        for card in copied:
            card.hint_color(color)
        before = sum(len(x.possible) for x in self.cards)
        after = sum(len(x.possible) for x in copied)
        return before - after

    def gain_hint_rank(self, rank):
        """Hypothesized number of possibilities eliminated by hinting a rank"""
        copied = deepcopy(self.cards)
        for card in copied:
            card.hint_rank(rank)
        before = sum(len(x.possible) for x in self.cards)
        after = sum(len(x.possible) for x in copied)
        return before - after

    def remove(self, index):
        """Play/Discard a card from hand; reset last hinted"""
        self.last_hinted = set()
        card = self.cards[index - 1]
        del self.cards[index - 1]
        self.get()
        return card


class Board:
    def __init__(self):
        self._count = {color: 0 for color in Color}

    def __getitem__(self, key):
        return self._count.get(key)

    def __str__(self):
        return "Board:\n" + " ".join(
            ["{}: {} |".format(col.name, self._count[col]) for col in sorted(Color)]
        )

    def playable(self, card):
        """Return true iff the card is playable"""
        return self._count[card._color] == card._rank - 1

    def play(self, card):
        """Try to play a card. Return True for successful play, o.w. False"""
        if self.playable(card):
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
        self._most_recent = None

    def __str__(self):
        res = "Trash:\n"
        for color in Color:
            res += ("  " + color.name + ":").ljust(10, " ")
            for rank in Rank:
                for i in range(self.count(Card(color, rank))):
                    res += str(rank.value) + " "
            res += "\n"
        return res

    def add(self, card):
        self._most_recent = card
        self._count[card] = self.count(card) + 1

    def count(self, card):
        return self._count.get(card, 0)

    def hasall(self, card):
        return self.count(card) == card_count[card._rank]

    @property
    def all(self):
        return [
            (c.name, r.name, self.count(Card(c, r))) for c, r in product(Color, Rank)
        ]

    @property
    def most_recent(self):
        return self._most_recent


class DataObject:
    def __init__(self, title, data=[], trials=set(), games=set()):
        self.title = title
        self.data = data
        self.trials = trials
        self.games = games
        self.plt = None

    def _plt_clear(self):
        if self.plt is None:
            self.plt = importlib.import_module("matplotlib.pyplot")
            self.plt.close()
        else:
            self.plt.close()

    def _get_scores(self, filter_func=lambda x: True, sort_func=lambda x: x["score"]):
        return [
            entry["score"]
            for entry in sorted(self.data, key=sort_func)
            if filter_func(entry)
        ]

    def _print_summary(self, scores, prefix=""):
        num = len(scores)
        print("=" * 32)
        print(prefix, "{} games".format(num))
        print("  average: {}".format(sum(scores) / num))
        print("  min:     {}".format(min(scores)))
        print("  25%:     {}".format(scores[num // 4]))
        print("  75%:     {}".format(scores[num // 4]))
        print("  max:     {}".format(max(scores)))
        print("  mode:    {}".format(max(scores, key=scores.count)))
        print("=" * 32)

    def log_game(self, game, trial=None, index=None):
        self.trials.add(trial)
        self.games.add(index)
        game_summary = game.summary
        game_summary.update({"trial": trial, "game": index})
        self.data.append(game_summary)

    def save_to_txt(self, txt_file):
        with open("txt_file", "w") as fout:
            fout.write('"index" "score" "turns" "hints" "hits"\n')
            for entry in self.data:
                fout.write(
                    "{} {} {} {} {}\n".format(
                        entry["game"],
                        entry["score"],
                        entry["turns"],
                        entry["hints"],
                        entry["hits"],
                    )
                )

    def save_to_pkl(self, pkl_file):
        pickle.dump(
            [self.title, self.data, self.trials, self.games], open(pkl_file, "wb")
        )

    @staticmethod
    def load_from_pkl(pkl_file):
        return DataObject(*pickle.load(open(pkl_file, "rb")))

    def print_summary(self):
        for index in self.games:
            self._print_summary(
                self._get_scores(lambda x: x["game"] == index),
                "game {}:".format(index),
            )

    def plot_density(self, png_file, index=None):
        self._plt_clear()
        if index is None:
            scores = self._get_scores()
        else:
            scores = self._get_scores(lambda x: x["game"] == index)
        self.plt.hist(scores, range(27), density=True)
        self.plt.xlabel("score")
        self.plt.ylabel("density")
        self.plt.title(
            "distribution of {} over {} games".format(self.title, len(scores))
        )
        self.plt.savefig(png_file)

    def plot_curve(self, png_file):
        self._plt_clear()
        indices = sorted(self.games)
        games = len(self.games)
        trials = len(self.trials)
        scores = [self._get_scores(lambda x: x["game"] == i) for i in indices]
        scores_mean = [sum(x) / trials for x in scores]
        scores_lower = [x[trials // 4] for x in scores]
        scores_upper = [x[3 * trials // 4] for x in scores]
        self.plt.plot(indices, scores_mean)
        self.plt.fill_between(indices, scores_lower, scores_upper, alpha=0.2)
        self.plt.xlabel("games")
        self.plt.ylabel("score")
        self.plt.title(
            "score of {} over {} games averaged over {} trials".format(
                self.title, games, len(self.trials)
            )
        )
        self.plt.savefig(png_file)

    def plot_difference(self, png_file):
        self._plt_clear()
        first = self._get_scores(
            lambda x: x["game"] == min(self.games), lambda x: x["trial"]
        )
        last = self._get_scores(
            lambda x: x["game"] == max(self.games), lambda x: x["trial"]
        )
        diff = [b - a for a, b in zip(first, last)]
        limit = int(max(max(diff), -min(diff))) + 1
        self.plt.hist(diff, range(-limit, limit), density=True)
        self.plt.xlabel("score difference")
        self.plt.ylabel("density")
        self.plt.title(
            "difference in game {} and game {} for {} over {} games".format(
                max(self.games), min(self.games), self.title, len(diff)
            )
        )
        self.plt.savefig(png_file)

    @staticmethod
    def plot_from_pkl(pkl_file, plot_type, png_file):
        getattr(DataObject.load_from_pkl(pkl_file), "plot_" + plot_type)(png_file)
