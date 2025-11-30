extends Node
class_name Microgame

signal game_over(score: int)
signal score_updated(score: int)

var current_score: int = 0

func _ready():
    print("Microgame started: " + name)

func add_score(points: int):
    current_score += points
    score_updated.emit(current_score)

func end_game():
    print("Game Over. Final Score: " + str(current_score))
    game_over.emit(current_score)
