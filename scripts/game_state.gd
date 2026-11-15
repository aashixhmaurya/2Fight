extends Node

# Shared match data for Hell training + final power round.
var loser_number = 1
var winner_number = 2
var round_num = 1
var resume_from_hell = false
## After clearing Hell, the next ground fight is the final power round (no Hell again).
var power_round = false
## Index 0 = Player 1, 1 = Player 2
var special_ready = [false, false] ## Hell clearer — Shift = 4s x2 damage
var heart_ready = [false, false] ## Round winner — Shift = heal +40 HP (cap 100)


func grant_special(player_number: int):
	if player_number == 1 or player_number == 2:
		special_ready[player_number - 1] = true


func consume_special(player_number: int):
	if player_number == 1 or player_number == 2:
		special_ready[player_number - 1] = false


func has_special(player_number: int) -> bool:
	if player_number == 1 or player_number == 2:
		return special_ready[player_number - 1]
	return false


func grant_heart(player_number: int):
	if player_number == 1 or player_number == 2:
		heart_ready[player_number - 1] = true


func consume_heart(player_number: int):
	if player_number == 1 or player_number == 2:
		heart_ready[player_number - 1] = false


func has_heart(player_number: int) -> bool:
	if player_number == 1 or player_number == 2:
		return heart_ready[player_number - 1]
	return false


func save_match(p_round_num: int):
	round_num = p_round_num


func clear_resume():
	resume_from_hell = false


func reset_all():
	special_ready = [false, false]
	heart_ready = [false, false]
	resume_from_hell = false
	power_round = false
	loser_number = 1
	winner_number = 2
	round_num = 1


func reset_rewards():
	reset_all()
