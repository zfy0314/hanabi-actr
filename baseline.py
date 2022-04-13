from random import choice, seed
from player import ActionType as AT
from player import Action, Player
import utils


class HardcodedPlayer(Player):
    def __init__(self, name, pnr):
        self.name = name
        self.pnr = pnr
        self.last_hinted = None

    def get_action(self, game):
        """
        Follow the following simple strategy

        1. whenever a card is playable, play the card; prioritize 5 for the bonus hint
        2. whenever being hinted at a possibly playable card, interpret it as playable
        3. hint partner to play, prioritize unambiguous hint
        4. discard useless cards first
        5. hint partner to discard or provide more information
        6. discard from the oldest
        """

        # alias
        hand = game.hands[self.pnr]
        rhand = range(1, 1 + len(hand))
        ppnr = 1 - self.pnr  # for 2 player game only
        phand = game.hands[ppnr]
        rphand = range(1, 1 + len(phand))
        test = game.board.playable

        # play playable cards
        utils._print("try to play for certain")
        playables = [i for i in rhand if hand[i].playable]
        if playables != []:
            try:
                index = [hand[i].get_rank(self.pnr) for i in playables].index({5}) + 1
            except ValueError:
                index = min(playables)
            return Action(AT.play, index, self.pnr)

        # play last hint
        utils._print("try to play last hint")
        if self.last_hinted is not None and hand[self.last_hinted].playable_possibly:
            return Action(AT.play, self.last_hinted, self.pnr)

        # hint to play
        hints = {}
        hints_info = {}
        hints_play = {}
        blocked = []
        utils._print("try to hint for play, process all hints in the meanwhile")
        if game.hints > 0:
            for cnl in ["color", "rank"]:
                for i in range(1, 6):
                    cards = [
                        (j, phand[j])
                        for j in rphand
                        if getattr(phand[j], "get_" + cnl)(self.pnr) == i
                    ]
                    utils._print(
                        "  if hint ",
                        cnl,
                        i,
                        [(j, test(card), card.playable_possibly) for j, card in cards],
                    )
                    action = Action(getattr(AT, "hint_" + cnl), i, ppnr)
                    gain = getattr(phand, "gain_hint_" + cnl)(i)
                    hints[action] = cards
                    if cards != [] and any(test(card) for i, card in cards):
                        if game.board.playable(cards[-1][1]):
                            hints_play[action] = gain
                        elif len(cards) > 1 and all(
                            test(card) for i, card in cards[:-1]
                        ):
                            blocked.append(cards[-1][0])
                    if cards == [] or (
                        not any(card.playable_possibly for i, card in cards)
                    ):
                        hints_info[action] = gain
            utils._print("got {} candidates".format(len(hints_play)))
            if len(hints_play) > 0:
                return max(hints_play.keys(), key=lambda x: hints_play[x])

        # discard useless card
        utils._print("try to discard useless card")
        for i in rhand:
            if hand[i].useless:
                return Action(AT.discard, i, self.pnr)
        utils._print("try to discard duplicate card")
        colors = {i: hand[i].get_color(self.pnr) for i in rhand}
        ranks = {i: hand[i].get_rank(self.pnr) for i in rhand}
        for i in rhand:
            for j in rhand:
                if (
                    i < j
                    and len(colors[i]) == 1
                    and len(ranks[i]) == 1
                    and colors[i] == colors[j]
                    and ranks[i] == ranks[j]
                ):
                    return Action(AT.discard, i, self.pnr)

        # hint to discard
        utils._print("try to hint for discard")
        if game.hints > 1 and len(hints_info) > 0:
            for hint, cards in sorted(hints.items(), key=lambda x: -len(x[1])):
                if len(cards) > 0 and all(card.useless for i, card in cards):
                    return hint

        # hint for maximum gain
        utils._print("try to hint for most information")
        utils._print({str(k): v for k, v in hints_info.items()})
        if game.hints > 2 and len(hints_info) > 0:
            return max(
                hints_info.keys(),
                key=lambda x: sum(blocked.count(i) for i in hints[x]),
            )

        # discard oldest unhinted card
        utils._print("default dicard")
        for i in rhand:
            if len(colors[i]) > 1 and len(ranks[i]) > 1:
                return Action(AT.discard, i, self.pnr)

        # discard randomly
        utils._print("random dicard")
        return Action(AT.discard, choice(rhand), self.pnr)

    def inform(self, pnr, action, game):
        if pnr == self.pnr:
            self.last_hinted = None
        if action.type in [AT.hint_color, AT.hint_rank] and action.pnr == self.pnr:
            # associate the hint with the most recent hinted card
            self.last_hinted = max(game.hands[self.pnr].last_hinted, default=None)


if __name__ == "__main__":
    from game import Game

    # from human import HumanPlayer

    # G = Game([HumanPlayer("Alice", 0, debug=True), HardcodedPlayer("Bob", 1)], seed=0)
    # score = G.run()
    # print("score: ", score)

    seed(0)
    n = 500
    utils.debugging = False
    scores = []
    for i in range(n):
        G = Game([HardcodedPlayer("Alice", 0), HardcodedPlayer("Bob", 1)])
        scores.append(G.run())
    print(
        "{} games:\n  avg: {}, min: {}, max: {}, mode: {}".format(
            n,
            sum(scores) / n,
            min(scores),
            max(scores),
            max(set(scores), key=scores.count),
        )
    )

    from matplotlib import pyplot as plt

    plt.hist(scores, range(27), density=True)
    plt.xlabel("score")
    plt.ylabel("desity")
    plt.title("distribution of baseline agent over {} games".format(n))
    plt.savefig("baseline_distribution.png")
