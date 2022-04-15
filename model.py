import actr
from player import ActionType as AT
from player import Action, Player


class ActrPlayer(Player):
    def __init__(self, name, pnr, model_path="ACT-R:final;model.lisp"):
        self.name = name
        self.pnr = pnr
        actr.load_act_r_model(model_path)
        actr.install_device(actr.open_exp_window("Hanabi", visible=False))
        self.response = ""

        self.ATmap = [None, "C", "R", "P", "D"]
        self.nrmap = [None, 1 - pnr, 1 - pnr, pnr, pnr]

    def _show_state(self, game):
        actr.clear_exp_window()

    def _get_key(self, model, key):
        self.response += key

    def get_action(self, game):

        # re-encode game state
        self._show_state(game)

        # get response from model for choosing an action
        actr.add_command(
            "key-press",
            self._get_key,
            "key press monitor",
        )
        actr.monitor_command("output-key", "key-press")
        actr.run(100)
        actr.remove_command_monitor("output-key", "key-press")
        actr.remove_command("key-press")

        # return action
        index = self.ATmap.index(self.response[0].upper())
        action = Action(AT(index), eval(self.response[1]), self.nrmap[index])
        self.response = ""
        return action

    def inform(self, pnr, action, game):
        pass


if __name__ == "__main__":
    from game import Game
    from human import HumanPlayer

    G = Game([HumanPlayer("Alice", 0, debug=True), ActrPlayer("Bob", 1)], seed=0)
    score = G.run()
    print("score: ", score)
