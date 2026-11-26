class_name DealerPartyMatch
extends RefCounted

## Pure Nearby v2 rules. The dealer host is intentionally not a player seat.
const MAX_CLIENTS := 5
const TOTAL_ROUNDS := 5
const INITIAL_BALANCE := GameConstants.INITIAL_BALANCE
const MIN_CHIP := 10_000
const REWARD_AMOUNT := 200_000
const MAX_REWARDS_PER_ROOM := 3

const PHASE_LOBBY := "lobby"
const PHASE_BETTING := "betting"
const PHASE_LOCKED := "locked"
const PHASE_SETTLED := "settled"
const PHASE_FINISHED := "finished"

var phase := PHASE_LOBBY
var round_number := 0
var players: Array[Dictionary] = []
var results: Array[String] = []
var round_summaries: Dictionary = {}
var _next_seat := 1

func add_player(player_id: String, display_name: String) -> bool:
	if phase != PHASE_LOBBY or player_id.is_empty() or players.size() >= MAX_CLIENTS:
		return false
	if _player_index(player_id) >= 0:
		return false
	players.append({
		"player_id": player_id,
		"seat": _next_seat,
		"name": _unique_name(_clean_name(display_name)),
		"connected": true,
		"spectator": false,
		"balance": INITIAL_BALANCE,
		"bets": GameConstants.empty_bets(),
		"ready": false,
		"round_stake": 0,
		"round_payout": 0,
		"round_net": 0,
		"total_net": 0,
		"wins": 0,
		"reward_count": 0,
		"reward_ids": [],
	})
	_next_seat += 1
	return true

func start_match() -> bool:
	if not [PHASE_LOBBY, PHASE_FINISHED].has(phase) or players.is_empty():
		return false
	if phase == PHASE_FINISHED:
		_reset_match_totals()
	round_number = 1
	results.clear()
	round_summaries.clear()
	_reset_round_state()
	phase = PHASE_BETTING
	return true

func place_bet(player_id: String, symbol: String, amount: int) -> bool:
	if phase != PHASE_BETTING or not GameConstants.SYMBOLS.has(symbol) or not GameConstants.CHIP_VALUES.has(amount):
		return false
	var index := _player_index(player_id)
	if index < 0:
		return false
	var player := players[index]
	if not player["connected"] or player["spectator"] or player["ready"]:
		return false
	if _total_bet(player) + amount > int(player["balance"]):
		return false
	var bets: Dictionary = player["bets"]
	bets[symbol] = int(bets.get(symbol, 0)) + amount
	return true

func clear_bets(player_id: String) -> bool:
	if phase != PHASE_BETTING:
		return false
	var index := _player_index(player_id)
	if index < 0 or players[index]["ready"]:
		return false
	players[index]["bets"] = GameConstants.empty_bets()
	return true

func confirm_bets(player_id: String) -> bool:
	if phase != PHASE_BETTING:
		return false
	var index := _player_index(player_id)
	if index < 0:
		return false
	var player := players[index]
	if not player["connected"] or player["spectator"] or player["ready"]:
		return false
	var stake := _total_bet(player)
	if stake <= 0 or stake > int(player["balance"]):
		return false
	player["balance"] = int(player["balance"]) - stake
	player["round_stake"] = stake
	player["ready"] = true
	if all_active_ready():
		phase = PHASE_LOCKED
	return true

func expire_betting() -> bool:
	if phase != PHASE_BETTING:
		return false
	# The host owns the deadline. At timeout, preserve every valid pending bet
	# instead of discarding a client's last-second input. Players who did not bet
	# are marked ready with a zero stake so they cannot hold the room open.
	for player: Dictionary in players:
		if not player["connected"] or player["spectator"] or player["ready"]:
			continue
		var stake := _total_bet(player)
		if stake > 0:
			player["balance"] = int(player["balance"]) - stake
		player["round_stake"] = stake
		player["ready"] = true
	phase = PHASE_LOCKED
	return true

func all_active_ready() -> bool:
	var active_count := 0
	for player: Dictionary in players:
		if not player["connected"] or player["spectator"]:
			continue
		active_count += 1
		if not player["ready"]:
			return false
	return active_count > 0

func settle(rolled_results: Array[String]) -> bool:
	if phase != PHASE_LOCKED or rolled_results.size() != 3:
		return false
	for symbol: String in rolled_results:
		if not GameConstants.SYMBOLS.has(symbol):
			return false
	results = rolled_results.duplicate()
	round_summaries.clear()
	for player: Dictionary in players:
		if not player["connected"] or player["spectator"] or not player["ready"]:
			continue
		# Multiplayer does not award the single-player daily mission bonus.
		var summary := RoundResolver.resolve(player["bets"], results, 0, true)
		player["round_payout"] = int(summary["payout"])
		player["round_net"] = int(summary["net"])
		player["total_net"] = int(player["total_net"]) + int(summary["net"])
		player["balance"] = int(player["balance"]) + int(summary["payout"])
		if int(summary["net"]) > 0:
			player["wins"] = int(player["wins"]) + 1
		player["spectator"] = int(player["balance"]) < MIN_CHIP
		round_summaries[player["player_id"]] = summary.duplicate(true)
	phase = PHASE_SETTLED
	return true

func advance_round() -> bool:
	if phase != PHASE_SETTLED:
		return false
	_remove_disconnected_players()
	if round_number >= TOTAL_ROUNDS or players.is_empty():
		phase = PHASE_FINISHED
		return true
	round_number += 1
	results.clear()
	round_summaries.clear()
	_reset_round_state()
	phase = PHASE_BETTING
	return true

func cancel_unsettled_round() -> bool:
	if not [PHASE_BETTING, PHASE_LOCKED].has(phase):
		return false
	for player: Dictionary in players:
		if player["ready"]:
			player["balance"] = int(player["balance"]) + int(player["round_stake"])
	results.clear()
	round_summaries.clear()
	_reset_round_state()
	phase = PHASE_BETTING
	return true

func disconnect_player(player_id: String) -> bool:
	var index := _player_index(player_id)
	if index < 0:
		return false
	if [PHASE_BETTING, PHASE_LOCKED].has(phase):
		cancel_unsettled_round()
		players.remove_at(index)
	elif phase == PHASE_SETTLED:
		players[index]["connected"] = false
	else:
		players.remove_at(index)
	if players.is_empty():
		phase = PHASE_LOBBY if round_number == 0 else PHASE_FINISHED
	return true

func grant_reward(player_id: String, reward_id: String) -> bool:
	var index := _player_index(player_id)
	if index < 0 or reward_id.is_empty():
		return false
	var player := players[index]
	var reward_ids: Array = player["reward_ids"]
	if reward_ids.has(reward_id) or int(player["reward_count"]) >= MAX_REWARDS_PER_ROOM:
		return false
	if int(player["balance"]) >= MIN_CHIP:
		return false
	reward_ids.append(reward_id)
	player["reward_count"] = int(player["reward_count"]) + 1
	player["balance"] = int(player["balance"]) + REWARD_AMOUNT
	player["spectator"] = false
	return true

func leaderboard() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for player: Dictionary in players:
		rows.append({
			"player_id": player["player_id"],
			"seat": player["seat"],
			"name": player["name"],
			"balance": player["balance"],
			"round_net": player["round_net"],
			"total_net": player["total_net"],
			"wins": player["wins"],
			"connected": player["connected"],
		})
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a["total_net"]) != int(b["total_net"]):
			return int(a["total_net"]) > int(b["total_net"])
		if int(a["wins"]) != int(b["wins"]):
			return int(a["wins"]) > int(b["wins"])
		return int(a["seat"]) < int(b["seat"])
	)
	for index in rows.size():
		rows[index]["rank"] = index + 1
	return rows

func snapshot() -> Dictionary:
	return {
		"phase": phase,
		"round_number": round_number,
		"players": players.duplicate(true),
		"results": results.duplicate(),
		"round_summaries": round_summaries.duplicate(true),
		"leaderboard": leaderboard(),
	}

func get_player(player_id: String) -> Dictionary:
	var index := _player_index(player_id)
	return players[index] if index >= 0 else {}

func _reset_match_totals() -> void:
	for player: Dictionary in players:
		player["balance"] = INITIAL_BALANCE
		player["total_net"] = 0
		player["wins"] = 0
		player["reward_count"] = 0
		player["reward_ids"] = []
		player["connected"] = true
		player["spectator"] = false

func _reset_round_state() -> void:
	for player: Dictionary in players:
		player["bets"] = GameConstants.empty_bets()
		player["ready"] = false
		player["round_stake"] = 0
		player["round_payout"] = 0
		player["round_net"] = 0
		player["spectator"] = int(player["balance"]) < MIN_CHIP

func _remove_disconnected_players() -> void:
	for index in range(players.size() - 1, -1, -1):
		if not players[index]["connected"]:
			players.remove_at(index)

func _total_bet(player: Dictionary) -> int:
	var total := 0
	for amount: Variant in player["bets"].values():
		total += int(amount)
	return total

func _player_index(player_id: String) -> int:
	for index in players.size():
		if players[index]["player_id"] == player_id:
			return index
	return -1

func _clean_name(value: String) -> String:
	var clean := value.strip_edges().replace("\n", " ").replace("\r", " ")
	while "  " in clean:
		clean = clean.replace("  ", " ")
	clean = clean.substr(0, 24)
	return clean if not clean.is_empty() else "Người chơi"

func _unique_name(base_name: String) -> String:
	var used: Dictionary = {}
	for player: Dictionary in players:
		used[str(player.get("name", "")).to_lower()] = true
	if not used.has(base_name.to_lower()):
		return base_name
	var suffix := 2
	while suffix <= MAX_CLIENTS + 1:
		var marker := " (%d)" % suffix
		var candidate := base_name.left(maxi(1, 24 - marker.length())) + marker
		if not used.has(candidate.to_lower()):
			return candidate
		suffix += 1
	return base_name.left(17) + " (khác)"
