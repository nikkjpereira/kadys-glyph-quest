from pathlib import Path
p=Path("tests/smoke.gd")
s=p.read_text()
anchor='    game.mode = "arcade"\n    game._start_level(0,1)\n'
assert anchor in s
addition='''    # A stalemate ends the round and awards partial stars, never prematurely.
    game.mode = "quest"
    game._start_level(0,1)
    var gems_left: Array[int] = []
    for i in range(64):
        if game.board[i] >= 0:
            gems_left.append(i)
    for i in range(gems_left.size()):
        game.board[gems_left[i]] = QuestRules.EMPTY if i >= 3 else i
    game._finish_or_save()
    if game.state != "victory" or game.earned_stars != 2:
        _fail("No-moves partial clear did not award two stars");return
    game._start_level(0,1)
    var sparse: Array[int] = []
    for i in range(64):
        if game.board[i] >= 0:
            sparse.append(i)
    for i in range(sparse.size()):
        game.board[sparse[i]] = QuestRules.EMPTY if i >= 3 else i
    game.start_gems = 3
    game._finish_or_save()
    if game.state != "failure":
        _fail("Low-clear-rate stalemate was not a loss");return
    game._start_level(0,1)
    var count_start := QuestRules.remaining(game.board)
    game._shuffle()
    if QuestRules.remaining(game.board) != count_start:
        _fail("Quest shuffle added or removed gems");return
'''
s=s.replace(anchor,addition+anchor,1)
p.write_text(s)
print("Added no-moves/partial-grade, failure and shuffle-no-refill test cases.")
